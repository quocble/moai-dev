from tornado.websocket import websocket_connect, WebSocketClientConnection
from tornado.ioloop import IOLoop
import sys

echo_uri = 'ws://localhost:8888/ws'
class myws():
	conn = None
	def __init__(self, uri):
		self.uri = uri
		w = websocket_connect(self.uri)
		w.add_done_callback(self.wsconnection_cb)

	def wsconnection_cb(self, conn):
		self.conn = conn.result()
    	conn.result().read_message(callback=self.message)

	def message(self, message):
		m = message.result()
		if m is None:
			print "disconn"
		else:
			print m

import signal

# def bot():
#     io_loop = IOLoop.instance()
#     myws(echo_uri)
#     IOLoop.instance().start()

# import threading


# def kill_threads(threads):
# 	print("kill all threads")
# 	for thread in threads:
# 		thread._Thread__stop()

def main():

	count = 1
	if len(sys.argv) >= 2:
		count = int(sys.argv[1])

	print "start " + str(count) + " bots"

	try:
		io_loop = IOLoop.instance()
		signal.signal(signal.SIGTERM, io_loop.stop)

		for n in range(count):
			myws(echo_uri)

		IOLoop.instance().start()
	except KeyboardInterrupt:
		io_loop.stop()

 #  threads = []
 #  for n in range(count):
 #  	thread = threading.Thread(target=bot)
 #  	thread.start()
 #  	threads.append(thread)

 #  try:
 #  	signal.signal(signal.SIGTERM, kill_threads)
	# for thread in threads:
	# 	thread.join()
 #  except KeyboardInterrupt:
 #    print("stopping..")	

if __name__ == '__main__':
	main()