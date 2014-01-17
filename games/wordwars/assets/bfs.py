
import string
import random
import math
import multiprocessing
from functools import partial
from joblib import Parallel, delayed
from multiprocessing import cpu_count

MAX_ROW = 4
MAX_COL = 4
DICT = set(line.strip() for line in open('dictionary_en.txt'))

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

# def search_words_at_start(board, start):
#     all_paths = []
#     queue = []
#     queue.append([start])
#     new_path = [start]
#     while queue:
#         path = queue.pop(0)
#         node = path[-1]
#         for adjacent in adjacent_letters(board, node):
#             if adjacent not in new_path:
#                 new_path.append(adjacent)
#                 queue.append(new_path)
#                 print(new_path)
#     return all_paths

board = []
def gen():
    b = []
    for n in range(16):
        b.append(random.choice(string.ascii_uppercase))
    return b

def to2d(board_flat):
    new_board = [['' for i in xrange(4)] for i in xrange(4)]
    for n in range(len(board_flat)):
        c = n % MAX_COL
        r = int(math.floor(n / MAX_ROW))
        new_board[r][c] = board_flat[n]
    return new_board
     
board = gen()
board = ['A','S','T', 'I', 'Y', 'B', 'E', 'N', 'D', 'E','R', 'P','A', 'R', 'F', 'O']
print(board)
b2d = to2d(board)

for r in range(MAX_COL):
    for c in range(MAX_ROW):
        print b2d[r][c] + ' ',
    print ''

all_words = search_all_words(to2d(board))
all_words_list = list(all_words)
all_words_list.sort(lambda x,y: cmp(len(x), len(y)))
print(all_words_list)
print("total words found " + str(len(all_words)))
