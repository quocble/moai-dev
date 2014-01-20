#!/usr/bin/env python
#
# Copyright 2009 Facebook
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
"""Simplified chat demo for websockets.

Authentication, error handling, etc are left as an exercise for the reader :)
"""

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

from collections import deque
from tornado.options import define, options

define("port", default=8888, help="run on the given port", type=int)

PLAYER_COUNT = 2
GAME_TIME = 30
LOADING_DELAY = 6

class Application(tornado.web.Application):
    def __init__(self):
        handlers = [
            (r"/", MainHandler),
            (r"/ws", ChatSocketHandler),
        ]
        settings = dict(
            cookie_secret="__TODO:_GENERATE_YOUR_OWN_RANDOM_VALUE_HERE__",
            template_path=os.path.join(os.path.dirname(__file__), "templates"),
            static_path=os.path.join(os.path.dirname(__file__), "static"),
            xsrf_cookies=True,
        )
        tornado.web.Application.__init__(self, handlers, **settings)


class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.render("index.html", messages=ChatSocketHandler.cache)

WORD_BAG = { 'A' : 9 , 'B' : 2, 'C' : 2, 'D' : 4, 'E' : 12, 'F' : 2, 'G' : 3,
                    'H' : 2, 'I' : 9, 'J' : 1, 'K' : 1, 'L' : 4, 'M' : 2, 'N' : 6, 
                    'O' : 8, 'P' : 2, 'Q' : 1, 'R' : 6, 'S' : 4, 'T' : 6, 'U' : 4,
                    'V' : 2, 'W' : 2, 'X' : 1, 'Y' : 2, 'Z' : 1 }

db = MySQLDatabase('wordwars', user='root',passwd='welcome321', host='mysql-finance.ci7tm9uowicf.us-east-1.rds.amazonaws.com')

class GameBoard(peewee.Model):
    board = peewee.CharField()
    possible_count = peewee.IntegerField()
    all_words = peewee.TextField()

    class Meta:
        database = db

class Game(object): 
    def __init__(self, players):
        self.players = players
        self.board = Game.makeBoard()
        self.words_play = []
        self.game_timer = threading.Timer(GAME_TIME + LOADING_DELAY + 1, self.game_over)
        self.game_timer.start()
        print ("making new game with board")
        print (self.board)

    # @classmethod
    # def makeBoard(self):
    #     bag = []
    #     for key, value in WORD_BAG.iteritems():
    #         for n in range(value) :
    #             bag.append(key)
    #     random.shuffle(bag)                
    #     board = bag[:16]
    #     return board

    @classmethod
    def makeBoard(self):
        try:   
            boards = GameBoard.select().where(GameBoard.possible_count > 150).order_by(fn.Rand()).limit(1)
            return boards[0]
        except GameBoard.DoesNotExist:
            print("no board")
 
    def notify_new_game_after(self, time):
        threading.Timer(time, self.notify_new_game).start()

    def notify_new_game(self):
        print("notify new game")
        player_obj = []
        for player in self.players:
            player_obj.append({'player_name' : 'Name X', 'profile_img' : player.profile_img })

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
            p.write_message(tornado.escape.json_encode(msg))

    def play_streak(self, player, streak):
        player.streak = streak

    def play_max_wlength(self, player, max_word, max_wlength):
        player.max_word = max_word
        player.max_wlength = max_wlength

    def game_over(self):
        print("notify game over")
        highest_streak = {'name' : '', 'streak' : 0}
        highest_word_length = {'name' : '', 'word' : '', 'max_wlength' : 0, }
        most_words = {'name' : '', 'count' : 0}
        scores = []

        for player in self.players:
            player.name = hex(id(self))
            if highest_streak['streak'] < player.streak:
                highest_streak['name'] = player.name
                highest_streak['streak'] = player.streak
            if highest_word_length['max_wlength'] < player.max_wlength:
                highest_word_length['name'] = player.name
                highest_word_length['word'] = player.max_word
                highest_word_length['max_wlength'] = player.max_wlength
            if most_words['count'] < player.total_words:
                most_words['name'] = player.name
                most_words['count'] = player.total_words
            scores.append({'name' : hex(id(self)), 'score' : player.score, 'profile_img' : player.profile_img })
        msg = { 'msgtype' : 'game_over', 'players' : scores, 'most_words' : most_words, 
                'longest_streak' : highest_streak, 'longest_word' : highest_word_length }
        for player in self.players:
            player.write_message(tornado.escape.json_encode(msg))


class ChatSocketHandler(tornado.websocket.WebSocketHandler):
    waiters = set()
    queue_players = deque() # queue of players looking for game.
    games   = []
    cache = []

    def allow_draft76(self):
        # for iOS 5.0 Safari
        return True

    def open(self):
        ChatSocketHandler.waiters.add(self)
        self.profile_img = 'https://s3.amazonaws.com/uifaces/faces/twitter/BillSKenney/128.jpg'

    def queue(self):
        if self in ChatSocketHandler.queue_players:
            print("cannot enqueue player " + hex(id(self)))
        else: 
            ChatSocketHandler.queue_players.append(self)
            print("add queue player " + hex(id(self)) + " total=" + str(len(ChatSocketHandler.queue_players)) + " players")

            # notify the other players as people are joining
            all_players_in_next_game = []
            for player in ChatSocketHandler.queue_players:
                all_players_in_next_game.append({'player_name' : 'Player ' + hex(id(player)), 'profile_img' : player.profile_img })

            msg = { 'msgtype' : 'player_join' , 'player' : all_players_in_next_game }
            self.write_message(msg)

            for player in ChatSocketHandler.queue_players:
                if(player != self):
                    msg = { 'msgtype' : 'player_join' , 'player' : [{'player_name' : 'Player ' + hex(id(self)), 'profile_img' : self.profile_img }] }
                    player.write_message(msg)

            players = []
            if len(ChatSocketHandler.queue_players) >= PLAYER_COUNT:
                for n in range(PLAYER_COUNT):
                    players.append(ChatSocketHandler.queue_players.popleft())
                
                new_game = Game(players)    
                ChatSocketHandler.games.append(new_game)
                new_game.notify_new_game_after(LOADING_DELAY)
                for player in players:
                    player.score = 0
                    player.max_word = ""
                    player.streak = 0
                    player.max_wlength = 0
                    player.current_game = new_game
                    player.total_words = 0

    def leave(self):
        try:
            ChatSocketHandler.queue_players.remove(self)
            print("leave player " + hex(id(self)))
        except ValueError:
            print("exception close")
       
    def on_close(self):
        try:
            ChatSocketHandler.waiters.remove(self)
            ChatSocketHandler.queue_players.remove(self)
            print("remove player " + hex(id(self)))
        except ValueError:
            print("exception close")

    def on_message(self, message):
        logging.info("got message %r", message)
        parsed = tornado.escape.json_decode(message)

        if parsed["msgtype"] == "play":
            print("score")
            self.current_game.play_word(self, parsed["word"])
        elif parsed["msgtype"] == "word_streak":
            print("word_streak")
            self.current_game.play_streak(self, parsed["count"])
        elif parsed["msgtype"] == "max_word_length":
            print("max_word_length")
            self.current_game.play_max_wlength(self, parsed["word"], parsed["count"])
        elif parsed["msgtype"] == "queue":
            self.queue()
        elif parsed["msgtype"] == "leave":
            self.leave()

        # chat = {
        #     "id": str(uuid.uuid4()),
        #     "body": parsed["body"],
        #     }
        # chat["html"] = tornado.escape.to_basestring(
        #     self.render_string("message.html", message=chat))

        # ChatSocketHandler.update_cache(chat)
        # ChatSocketHandler.send_updates(chat)


def main():

    tornado.options.parse_command_line()
    app = Application()
    app.listen(options.port)
    print("Started server")
    tornado.ioloop.IOLoop.instance().start()


if __name__ == "__main__":
    main()
