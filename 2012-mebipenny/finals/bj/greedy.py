from __future__ import division
from territory import *
import json
import collections
import itertools

class GameBot:
	name = 'greedy'
	def __init__(self, server, game, player_id):
		self.server = server
		self.game = game
		self.player_id = player_id

	def player(self):
		return self.game.players[self.player_id]

	def move_for_tile(self, tile):
		armies = self.game.armiesAdjacentToTile(tile)

		score = 0
		note = None
		favor = self.player_id
		unique_owners = {army.owner for army in armies}
		if len(unique_owners) == 0:
			# not next to anybody
			score = 0

		elif len(unique_owners) == 1:
			owner = unique_owners.pop()
			largest_army = sorted(armies, key=lambda x: len(x.claims), reverse=True)[0]

			if owner == self.player().id:
				score = 100 +  len(largest_army.claims)
				note = 'Build me'
			else:
				score = -100 -  len(largest_army.claims)
				note = 'Build other'


		elif len(unique_owners) > 1:
			my_armies = filter(lambda x: x.owner == self.player().id, armies)
			other_armies = filter(lambda x: x.owner != self.player().id, armies)

			my_size = sum([len(army.claims) for army in my_armies]) + 1
			other_size = sum([len(army.claims) for army in other_armies])
			
			if my_size > other_size:
				score = (1 + other_size) * 100 + my_size
				note = 'Merge in favor'
			else:
				score = (1 + my_size) * -100 -  other_size
				note = 'Merge against'

			if len(my_armies) == 0:
				smallest_army = sorted(other_armies, key=lambda x: len(x.claims))[0]
				note = 'Merge unrelated'
				favor = smallest_army.owner


		return Move(tile, score, favor, note)

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
			return None

		tiles = self.player().hand

		moves = []
		for tile in tiles:
			move = self.move_for_tile(tile)
			moves.append(move)

		moves = sorted(moves, key=lambda x: x.score, reverse=True)

		for move in moves:
			print move

		move = moves[0]


		if move.score >= 0:
			return move
		elif self.chance_favorable_draw() > 0.3: 
			print "Choosing to play, in hope of a better draw"
			return move
		else:
			return None

	def chance_favorable_draw(self):
		favorable = 0
		for x in range(self.game.rows):
			for y in range(self.game.cols):
				t = Tile(x, y)
				if self.game.claims_map.get(t) is None:
					move = self.move_for_tile(t)
					if move.score >= 0:
						favorable += 1
		
		total_outstanding = self.game.rows * self.game.cols - len(self.game.claims_map)

		return favorable / total_outstanding





	def take_turn(self):
		player = self.player()

	
		move = self.select_tile()
		if move is None:
			tile = None
			body = '"PASS"'
		else:
			tile = move.tile
			body = json.dumps({'tile': move.tile.to_json(), 'favor': move.favor})

		print "playing", move, player.id
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
