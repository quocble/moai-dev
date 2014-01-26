import unittest
import tornado
from mockito import mock, verify
from tornado.testing import AsyncHTTPTestCase, LogTrapTestCase
from game_server import *

TOKEN = "CAACEdEose0cBABaPj9m1s378ZAS3NAgR7V6NAhHvo1YS9gd1d22c1NQ6abTxImrDZC0ZCfQweBAv6YdNIS290VWyXqfHK16u7bx4gEZCMyFQuuqEhftJLeyqEb9GxAyJ89Qv4CHJX4zEOZAPdHaDWa8gAkrRsLevqsvsL7iGqJofjhs1SqXh0wHwBZACU782QZD"

class  GameServerTest(AsyncHTTPTestCase, LogTrapTestCase):
    _http_success_code = 200
    _facebook_login = "/login/fb"

    def setUp(self):
        AsyncHTTPTestCase.setUp(self)

    def get_app(self):
        return GameServerWebApp()

    def test_facebook_login(self):
        data = { "access_token" : TOKEN }
        self.http_client.fetch(self.get_url(self._facebook_login), self.stop, method="POST", body= tornado.escape.json_encode(data))
        response = self.wait()
        self.assertEqual(self._http_success_code, response.code)
        parsed = tornado.escape.json_decode(response.body)
        self.assertEqual("10013794", parsed["user_id"])
        self.assertEqual("quocble", parsed["username"])

if __name__ == '__main__':
    unittest.main()