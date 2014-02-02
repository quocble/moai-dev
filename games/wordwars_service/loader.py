
import string
import random
import math
import multiprocessing
from functools import partial
from joblib import Parallel, delayed
from multiprocessing import cpu_count
import peewee
from peewee import *
import json 
import sys

MAX_ROW = 4
MAX_COL = 4
DICT = set(line.strip() for line in open('../wordwars/assets/dictionary_en.txt'))

def search_all_words_by_n(board, n):
    c = n % MAX_COL
    r = int(math.floor(n / MAX_ROW))
    return search_words_at_start(board, (c, r, board[r][c]), [], [(c,r, board[r][c])])

def search_all_words(board):
    words = set()

    parallel  = Parallel(n_jobs=cpu_count())
    _ph = delayed(search_all_words_by_n)
    result = parallel(_ph(board, n) for n in range(16))
    #print(result)

    for w in result:
        for w2 in w:
            words.add(w2)
    return words

    # words = set()
    # for c in range(MAX_COL):
    #     for r in range(MAX_ROW):
    #        cword = search_words_at_start(board, (c, r, board[r][c]), [], [(c,r, board[r][c])])
    #        #print(cword)
    #        for w in cword:
    #             words.add(w)
    # return words

def adjacent_letters(board, loc):
    result = []
    x = loc[0]
    y = loc[1]

    if x > 0 :
        result.append((x-1, y, board[y][x-1]))         # <-
        if y > 0 :
            result.append((x-1, y-1, board[y-1][x-1])) #  \
        if y < MAX_ROW - 1 :
            result.append((x-1, y+1, board[y+1][x-1])) #  /-
    if x < MAX_COL - 1:
        result.append((x+1, y, board[y][x+1]))         # ->
        if y > 0 :
            result.append((x+1, y-1, board[y-1][x+1])) # -/
        if y < MAX_ROW - 1 :
            result.append((x+1, y+1, board[y+1][x+1])) # -\

    if y > 0 :
        result.append((x, y-1, board[y-1][x]))
    if y < MAX_ROW - 1:
        result.append((x, y+1, board[y+1][x]))

    # print("edges ")
    # print(result)
    return result

def get_word(path):
    word = ""
    for item in path:
        word += item[2]
    return word

def search_words_at_start(board, search, all_paths, current_path = []):
    for adjacent in adjacent_letters(board, search):
        if adjacent not in current_path:
            path = list(current_path)
            path.append(adjacent)
            
            word = get_word(path)
            if word in DICT:
                all_paths.append(word)
            search_words_at_start(board, adjacent, all_paths, path)
    return all_paths

board = []
def gen():
    distr = 'aaaaaaaaabbccddddeeeeeeeeeeeeffggghhiiiiiiiiijkllllmmnnnnnnooooooooppqrrrrrrssssttttttuuuuvvwwxyyz'
    bag = list(distr.upper())
    random.shuffle(bag)                
    board = bag[:16]
    return board

def to2d(board_flat):
    new_board = [['' for i in xrange(4)] for i in xrange(4)]
    for n in range(len(board_flat)):
        c = n % MAX_COL
        r = int(math.floor(n / MAX_ROW))
        new_board[r][c] = board_flat[n]
    return new_board

def generate_all_combos(board):
    all_words = search_all_words(board)
    all_words_list = list(all_words)
    all_words_list.sort(lambda x,y: cmp(len(x), len(y)))
    print(all_words_list)
    print("total words found " + str(len(all_words)))
    return all_words_list

db = MySQLDatabase('wordwars', user='root',passwd='welcome321', host='mysql-finance.ci7tm9uowicf.us-east-1.rds.amazonaws.com')

class GameBoard(peewee.Model):
    board = peewee.CharField()
    possible_count = peewee.IntegerField()
    all_words = peewee.TextField()

    class Meta:
        database = db

def generate_random_board():
    board = gen()
    generate_board(board)

def generate_board(board):
    b2d = to2d(board)
    for r in range(MAX_COL):
        for c in range(MAX_ROW):
            print b2d[r][c] + ' ',
        print ''

    board_str = ''.join(board) 
    try:   
        board_from_db = GameBoard.get(GameBoard.board == board_str)
    except GameBoard.DoesNotExist:
        print("adding " + board_str)
        combos = generate_all_combos(b2d)
        possible_count = len(combos)
        board = GameBoard(board=board_str, possible_count=possible_count, all_words=json.dumps(combos))
        board.save()	

def main():

	start = int(sys.argv[1])
	# print("generating " + str(count) + " words")

	# for n in range(count):
	#     generate_board()

	games = list(line.strip() for line in open('games/boards_en.txt'))
	
	print("Starting from index = " + str(start))
	print("Total games = ",len(games))

	for index in range(start, len(games)) :
		board = games[index]
		print("load game " + str(index) + " : " + board)
		generate_board(list(board))

if __name__ == "__main__":
  #websocket.enableTrace(True)
  try:
      main()
  except Exception as e:
      print(e)