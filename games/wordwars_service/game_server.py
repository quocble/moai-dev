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

from collections import deque
from tornado.options import define, options

define("port", default=8888, help="run on the given port", type=int)

PLAYER_COUNT = 1

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
            boards = GameBoard.select().order_by(fn.Rand()).limit(1)
            return boards[0]
        except GameBoard.DoesNotExist:
            print("no board")

    def notify_new_game(self):
        print("notify new game")
        for player in self.players:
            index = self.players.index(player) 
            board_arr = list(self.board.board)
            msg = { 'msgtype' : 'new', 'board' : board_arr, 'your_index' : index , 'player_count' : len(self.players) }
            player.write_message(tornado.escape.json_encode(msg))

    def play_word(self, player , word):
        print("player " + hex(id(self)) + " played " + word)
        point = 0
        if word not in self.words_play :
            point = 10

        player.score += point
        msg = { 'msgtype' : 'score' , 'score' : player.score, 'player_index' : self.players.index(player) , 'word' : word, 'point' : point }

        for p in self.players:
            p.write_message(tornado.escape.json_encode(msg))

class ChatSocketHandler(tornado.websocket.WebSocketHandler):
    waiters = set()
    queue_players = deque() # queue of players looking for game.
    games   = []
    cache = []
    player_per_game = PLAYER_COUNT

    def allow_draft76(self):
        # for iOS 5.0 Safari
        return True

    def open(self):
        ChatSocketHandler.waiters.add(self)

    def queue(self):
        if self in ChatSocketHandler.queue_players:
            print("cannot enqueue player " + hex(id(self)))
        else: 
            ChatSocketHandler.queue_players.append(self)
            print("add queue player " + hex(id(self)) + " total=" + str(len(ChatSocketHandler.queue_players)) + " players")

            players = []
            if len(ChatSocketHandler.queue_players) >= ChatSocketHandler.player_per_game :
                for n in range(ChatSocketHandler.player_per_game):
                    players.append(ChatSocketHandler.queue_players.popleft())
                
                new_game = Game(players)    
                ChatSocketHandler.games.append(new_game)
                new_game.notify_new_game()
                for player in players:
                    player.score = 0
                    player.current_game = new_game

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
        elif parsed["msgtype"] == "queue":
            self.queue()

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
