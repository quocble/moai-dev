#!/usr/bin/env python

import logging
import tornado.escape
import tornado.ioloop
import tornado.options
import tornado.web
import tornado.websocket
import os.path
import uuid
import random
import peewee
from peewee import *
import json 
import sys
import threading
import base64
import os
import facebook
import datetime

from collections import deque
from tornado.options import define, options

define("port", default=8888, help="run on the given port", type=int)

PLAYER_COUNT = 2
GAME_TIME = 30
LOADING_DELAY = 6

db = MySQLDatabase('wordwars', user='root',passwd='welcome321', host='mysql-finance.ci7tm9uowicf.us-east-1.rds.amazonaws.com')

def make_secret():
    return base64.encodestring(os.urandom(24)).replace('\n', '')

class GameBoard(peewee.Model):
    board = peewee.CharField()
    possible_count = peewee.IntegerField()
    all_words = peewee.TextField()

    class Meta:
        database = db

class User(peewee.Model):
    user_type = peewee.IntegerField()    
    user_id = peewee.CharField()
    secret = peewee.CharField()
    fb_token = peewee.TextField()
    balance = peewee.IntegerField()
    first_name = peewee.CharField()
    last_name = peewee.CharField()
    username = peewee.CharField()
    profile_img = peewee.CharField()
    created_date = peewee.DateTimeField(default=datetime.datetime.now)

    class Meta:
        database = db

    @classmethod
    def find_user_secret(user_id, secret):
        return User.get( (User.secret  == secret) & (User.user_id == user_id) )

    @classmethod
    def find_user(self, user_id):
        return User.get( User.user_id == user_id )

    @classmethod
    def create_with_profile(self, profile, token):
        user = User()
        user.user_type = 0        
        user.fb_token = token
        user.first_name = profile["first_name"]
        user.last_name = profile["last_name"]
        user.username = profile["username"]
        user.user_id = profile["id"]
        user.secret = make_secret()
        user.save()
        return user

    @classmethod
    def create_user_only(self, username):
        user = User()
        user.user_type = 1
        user.fb_token = ""
        user.first_name = username
        user.last_name = ""
        user.username = username
        user.user_id = username
        user.secret = make_secret()
        user.profile_img = ""
        user.save()
        return user        

    def update_with_profile(self, profile, token):
        self.fb_token = token
        self.first_name = profile["first_name"]
        self.last_name = profile["last_name"]
        self.username = profile["username"]

class GameServerWebApp(tornado.web.Application):
    def __init__(self):
        handlers = [
            (r"/", MainHandler),
            (r"/ws", PlayerHandler),
            (r"/login/fb", FBLoginHandler),
            (r"/store/purchase", StorePurchaseHandler)
        ]
        settings = dict(
            cookie_secret="__TODO:_GENERATE_YOUR_OWN_RANDOM_VALUE_HERE__",
            template_path=os.path.join(os.path.dirname(__file__), "templates"),
            static_path=os.path.join(os.path.dirname(__file__), "static"),
            xsrf_cookies=False,
        )
        tornado.web.Application.__init__(self, handlers, **settings)


class FBLoginHandler(tornado.web.RequestHandler):
    def post(self):
        data = json.loads(self.request.body)
        fb_token = data['access_token']
        graph = facebook.GraphAPI(fb_token)
        profile = graph.get_object("me")
        try:
            user = User.find_user(profile["id"])
        except User.DoesNotExist:
            user = None

        if user : 
            user.update_with_profile(profile, fb_token)
        else :
            user = User.create_with_profile(profile, fb_token)
        output = { 'user_id' : user.user_id, 
                    'secret' : user.secret , 
                    'username' : user.username, 
                  }        
        self.write(output)

class StorePurchaseHandler(tornado.web.RequestHandler):
    def post(self):
        token = self.get_argument('token')

class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.render("index.html", messages=PlayerHandler.cache)

class Game(object): 
    def __init__(self, players):
        self.players = players
        self.board = Game.makeBoard()
        self.words_play = []
        self.game_timer = threading.Timer(GAME_TIME + LOADING_DELAY + 1, self.game_over)
        self.game_timer.start()
        print ("making new game with board")
        print (self.board)

    @classmethod
    def makeBoard(self):
        try:   
            boards = GameBoard.select().where(GameBoard.possible_count > 150).order_by(fn.Rand()).limit(1)
            return boards[0]
        except GameBoard.DoesNotExist:
            print("no board")
 
    def notify_new_game_after(self, time):
        self.notify_countdown_timer(LOADING_DELAY)
        threading.Timer(time, self.notify_new_game).start()

    def notify_countdown_timer(self, time):
        for player in self.players:
            msg = { 'msgtype' : 'countdown', 'time' : LOADING_DELAY }
            player.write_message(tornado.escape.json_encode(msg))

    def notify_new_game(self):
        print("notify new game")
        player_obj = []
        for player in self.players:
            player_obj.append(player.get_data())

        for player in self.players:
            index = self.players.index(player) 
            board_arr = list(self.board.board)
            msg = { 'msgtype' : 'new', 'board' : board_arr, 'your_index' : index , 'players' : player_obj , 'game_time' : GAME_TIME }
            player.write_message(tornado.escape.json_encode(msg))

    def play_word(self, player , word):
        print("player " + hex(id(self)) + " played " + word)
        point = 0
        if word not in self.words_play :
            point = 10

        player.total_words += 1
        player.score += point
        msg = { 'msgtype' : 'score' , 'score' : player.score, 'player_index' : self.players.index(player) , 'word' : word, 'point' : point }

        for p in self.players:
            if p.disconnected:
                continue            
            p.write_message(tornado.escape.json_encode(msg))

    def play_streak(self, player, streak):
        player.streak = streak

    def play_max_wlength(self, player, max_word, max_wlength):
        player.max_word = max_word
        player.max_wlength = max_wlength

    def player_left(self, player):
        player.disconnected = True  # don't remove but let everyone know he left
        for p in self.players:
            if p != player:
                msg = { 'msgtype' : 'player_left' ,  'user_name' : player.get_username() }
                p.write_message(tornado.escape.json_encode(msg))

    def game_over(self):
        print("notify game over")
        highest_streak = {'name' : '', 'streak' : 0}
        highest_word_length = {'name' : '', 'word' : '', 'max_wlength' : 0, }
        most_words = {'name' : '', 'count' : 0}
        scores = []

        for player in self.players:
            if highest_streak['streak'] < player.streak:
                highest_streak['name'] = player.get_username()
                highest_streak['streak'] = player.streak
            if highest_word_length['max_wlength'] < player.max_wlength:
                highest_word_length['name'] = player.get_username()
                highest_word_length['word'] = player.max_word
                highest_word_length['max_wlength'] = player.max_wlength
            if most_words['count'] < player.total_words:
                most_words['name'] = player.name
                most_words['count'] = player.total_words
            scores.append({'name' : player.get_username(), 'score' : player.score, 'profile_img' : player.get_profile_img() })
        msg = { 'msgtype' : 'game_over', 'players' : scores, 'most_words' : most_words, 
                'longest_streak' : highest_streak, 'longest_word' : highest_word_length }
        print(msg)
        for player in self.players:
            if player.disconnected:
                continue            
            player.write_message(tornado.escape.json_encode(msg))
            player.current_game = None # Game do not exist anymore
        PlayerHandler.games.remove(self)

class PlayerHandler(tornado.websocket.WebSocketHandler):
    waiters = set()
    queue_players = deque() # queue of players looking for game.
    games   = []
    cache = []

    def allow_draft76(self):
        # for iOS 5.0 Safari
        return True

    def get_username(self):
        if self.profile.user_id == "bot":
            return "Bot"
        else:
            return self.profile.user_id

    def get_profile_img(self):
        if self.profile.user_id == "bot":
            return ""
        else:        
            return "http://graph.facebook.com/" + self.profile.user_id + "/picture?type=small"

    def get_data(self):
        return {'user_name' : self.get_username(), 'profile_img': self.get_profile_img() }

    def auth(self, user_id, secret):
        try:
            user = User.find_user(user_id)
        except User.DoesNotExist:
            user = None
        self.profile = user    
        print("identified as " + self.profile.user_id)

    def open(self):
        print("client connected")
        PlayerHandler.waiters.add(self)

    def queue(self):
        if self in PlayerHandler.queue_players:
            print("cannot enqueue player " + hex(id(self)))
        else: 
            PlayerHandler.queue_players.append(self)
            print("add queue player " + self.get_username() + " total=" + str(len(PlayerHandler.queue_players)) + " players")

            # notify the current player about everyone else
            all_players_in_next_game = []
            for player in PlayerHandler.queue_players:
                all_players_in_next_game.append(player.get_data())

            msg = { 'msgtype' : 'player_join' , 'player' : all_players_in_next_game }
            self.write_message(msg)

            # notify each person previously that the new player join
            for player in PlayerHandler.queue_players:
                if(player != self):
                    msg = { 'msgtype' : 'player_join' , 'player' : [ self.get_data() ] }
                    player.write_message(msg)

            players = []
            if len(PlayerHandler.queue_players) >= PLAYER_COUNT:

                for n in range(PLAYER_COUNT):
                    players.append(PlayerHandler.queue_players.popleft())
                
                new_game = Game(players)    
                PlayerHandler.games.append(new_game)
                new_game.notify_new_game_after(LOADING_DELAY)

                for player in players:
                    player.score = 0
                    player.max_word = ""
                    player.streak = 0
                    player.max_wlength = 0
                    player.current_game = new_game
                    player.total_words = 0
                    player.disconnected = False

    def leave(self):
        if self in PlayerHandler.queue_players:
            PlayerHandler.queue_players.remove(self)
            print("leave player " + hex(id(self)))

        if self.current_game:
            self.current_game.player_left(self)
               
    def on_close(self):
        try:
            PlayerHandler.waiters.remove(self)
            PlayerHandler.queue_players.remove(self)
            print("remove player " + hex(id(self)))
        except ValueError:
            print("exception close")    

    def on_message(self, message):
        logging.info("got message %r", message)
        parsed = tornado.escape.json_decode(message)

        if parsed["msgtype"] == "auth":
            self.auth(parsed["user_id"], parsed["secret"])
        elif parsed["msgtype"] == "play":
            print("score")
            self.current_game.play_word(self, parsed["word"])
        elif parsed["msgtype"] == "word_streak":
            print("word_streak")
            self.current_game.play_streak(self, parsed["count"])
        elif parsed["msgtype"] == "max_word_length":
            print("max_word_length")
            self.current_game.play_max_wlength(self, parsed["word"], parsed["count"])
        elif parsed["msgtype"] == "queue" and self.profile:
            self.queue()
        elif parsed["msgtype"] == "leave":
            self.leave()

def start_app(port):
    app = GameServerWebApp()
    app.listen(port)
    print("Started server")
    tornado.ioloop.IOLoop.instance().start()

def main():
    tornado.options.parse_command_line()
    start_app(options.port)

if __name__ == "__main__":
    main()
