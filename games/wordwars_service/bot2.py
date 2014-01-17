#!/usr/bin/python
import websocket
import thread
import time
import sys
import threading
import Queue
import json
import logging

logging.basicConfig()

max_row = 4
max_col = 4

def kill_threads(threads):
  print("kill all threads")
  for thread in threads:
    thread._Thread__stop()

def find_all_words(board):
  words = []
  for n in range(16):
    words.extend(find_from_pos(board, 16))
  return words

def get_at(board, x, y):
  return board[(y*max_col) + x]

def graph(board, path):
  neighbors = []
  c = path % max_row
  r = path % math_col
  print("graph -> " + str(path) + " c=" + str(c) + " r=" + str(r))

def find_from_pos(board, n):
    print("search at " + str(n))
    q = Queue.Queue()
    q.put(n)
    visited = set([n])

    words = []
    while not q.empty():
        path = q.get()
        for node in graph(board, path):
            if node not in visited:
                visited.add(node)
                q.put(node)
    return words

class Bot(object): 

  def __init__(self):
    ws = websocket.WebSocketApp("ws://localhost:8888/ws",
                              on_message = self.on_message,
                              on_error = self.on_error,
                              on_close = self.on_close)
    ws.on_open = self.on_open
    self.ws = ws
    ws.run_forever()

  def on_message(self, ws, message):
    print message
    obj = json.loads(message)
    if obj["type"] == "new" :
      print("new game!!!")
      self.board = obj["board"]
      possible_words = find_all_words(self.board)
      print(possible_words)

  def on_error(self, ws, error):
    print error

  def on_close(self, ws):
    print "### closed ###"

  def on_open(self, ws):
    print "open"

def main():
  count = 1
  if len(sys.argv) >= 2:
    count = int(sys.argv[1])

  print "start " + str(count) + " bots"
  
  word_dict = set(line.strip() for line in open('../wordwars/assets/dictionary_en.txt'))
  print "load dictionary " + str(len(word_dict)) + " words"

  # for n in range(count):
  #   bot = Bot()

  threads = []
  for n in range(count):
    thread = threading.Thread(target=Bot)
    threads.append(thread)
    thread.start()

  while len(threads) > 0:
    try:
    # Join all threads using a timeout so it doesn't block
    # Filter out threads which have been joined or are None
      threads = [t.join(1) for t in threads if t is not None and t.isAlive()]
    except KeyboardInterrupt:
      print "Ctrl-c received! Sending kill to threads..."
      kill_threads(threads)

if __name__ == "__main__":
  #websocket.enableTrace(True)
  main()