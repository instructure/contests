from httplib import *
from territory import *
import json
import operator




class GameBot:
	name = 'prefer_own'
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

	def select_tile(self):
		if self.is_game_set():
			return None, None

		tiles = self.player().hand

		weighted_tiles = {}
		favor = self.player_id
		for tile in tiles:
			armies = self.game.armiesAdjacentToTile(tile)

			unique_owners = {army.owner for army in armies}
			if len(unique_owners) == 0:
				# not next to anybody
				weighted_tiles[tile] = 0

			elif len(unique_owners) == 1:
				owner = unique_owners.pop()

				if owner == self.player().id:
					print "{} is only next to me!".format(tile)
					weighted_tiles[tile] = 10
				else:
					weighted_tiles[tile] = -10


			elif len(unique_owners) > 1:
				print "{} is next to multiple owners".format(tile)
				weighted_tiles[tile] = 0
				if self.player_id not in unique_owners:
					favor = unique_owners.pop()

		sorted_tiles = sorted(weighted_tiles.iteritems(), key=operator.itemgetter(1), reverse=True)
		if len(sorted_tiles) == 0:
			return None, None
		return (sorted_tiles[0][0], favor)



	def take_turn(self):
		player = self.player()

		tile, favor = self.select_tile()

		if tile is not None:
			move = {'tile': tile.to_json(), 'favor': player.id}
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

