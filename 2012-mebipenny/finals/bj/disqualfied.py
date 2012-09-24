from httplib import *
from territory import *
import json




class GameBot:
	name = 'disqualified'
	def __init__(self, server, game, player_id):
		self.server = server
		self.game = game
		self.player_id = player_id

	def take_turn(self):

		tile = Tile(100, 100)
		favor = '12345'
		move = {'tile': tile.to_json(), 'favor': favor}
		body = json.dumps(move)


		print "playing", move
		resp = self.server.post('/moves', body, self.game.token)

		if resp.status == 403:
			print "Invalid move. Disqualified. :("
			self.game.status = 'completed'
		elif resp.status == 200:
			token = resp.getheader('X-Turn-Token')
			self.game.token = token

			body = json.loads(resp.read())
			delta = GameDelta.from_json(body)
			self.game.update(delta)
		else:
			body = resp.read()
			raise RuntimeError("Unexpected response: {}, {}".format(resp.status, body))




if __name__ == "__main__":
	runWithBot(GameBot)

