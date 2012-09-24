from httplib import *
from territory import *
import json




class GameBot:
	name = 'random'
	def __init__(self, server, game, player_id):
		self.server = server
		self.game = game
		self.player_id = player_id

	def player(self):
		return self.game.players[self.player_id]


	def is_game_set(self):
		board_size = self.game.rows * self.game.cols
		other_scores = [x.score for x in self.game.players.values() if x.id != self.player().id and x.score is not None ]

		if self.player().score > board_size * 0.6 and max(other_scores) < board_size * 0.2:
			print "Passing, because I've already won"
			return True

		if self.player().score < board_size * 0.1 and max(other_scores) > board_size * 0.6:
			print "Passing, because I've already lost"
			return True

		return False

	def take_turn(self):

		player = self.player()
		favor = player.id

		try:
			tile = player.hand[0]
		except:
			tile = None

		if self.is_game_set():
			tile = None


		if tile is not None:
			armies = self.game.armiesAdjacentToTile(tile)
			unique_owners = {army.owner for army in armies}
			if len(unique_owners) > 0 and player.id not in unique_owners:
				favor = unique_owners.pop()

			move = {'tile': tile.to_json(), 'favor': favor}
			body = json.dumps(move)
		else:
			move = '"PASS"'
			body = '"PASS"'


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

