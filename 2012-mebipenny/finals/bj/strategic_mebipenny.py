from __future__ import division
from territory import *
import json
import collections
import itertools

class GameBot:
	name = 'strategic_old'
	def __init__(self, server, game, player_id):
		self.server = server
		self.game = game
		self.player_id = player_id

	def player(self):
		return self.game.players[self.player_id]

	def move_for_tile(self, tile, hand):
		armies = self.game.armiesAdjacentToTile(tile)

		score = 0
		note = None
		favor = self.player_id
		unique_owners = {army.owner for army in armies}
		if len(unique_owners) == 0:
			# not next to anybody
			likely_owners = self.likely_future_owners(tile)
			likely_others = [x for x in likely_owners if x != self.player_id]
			likely_me = len(likely_others) != len(likely_owners)

			if len(likely_owners) == 1 and likely_owners[0] == self.player_id:
				score = 1
				note = 'Likely me'
			elif (not likely_me) and len(likely_others) > 1:
				score = -1
				note = 'Likely other'
			else:
				good_adjacents = 0
				for t in hand:
					if not tile.is_adjacent(t):
						continue
					move = self.move_for_tile(t, [])
					if move.score >= 0:
						good_adjacents += 1

				score = good_adjacents
				if score > 0:
					note = 'Adjacent to hand'

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

	def select_move(self):
		if self.is_game_set():
			return None

		tiles = self.player().hand

		moves = []
		for tile in tiles:
			move = self.move_for_tile(tile, tiles)
			moves.append(move)

		moves = sorted(moves, key=lambda x: x.score, reverse=True)


		for move in moves:
			print move
		#print "chance at favorable: {:.2f}".format(self.chance_favorable_draw())

		if len(moves) == 0:
			return None


		move = moves[0]

		if move.score >= 0:
			return move
		elif self.game.draw_size > 0 and self.expected_draw_value() > move.score: 
			print "Choosing to play, in hope of a better draw"
			return move
		else:
			print "Passing"
			return None

	def expected_draw_value(self):
		hand = self.player().hand
		values = []
		for x in range(self.game.rows):
			for y in range(self.game.cols):
				t = Tile(x, y)
				if self.game.claims_map.get(t) is None:
					move = self.move_for_tile(t, hand)
					values.append(move.score)

		expected_value = sum(values) / len(values)
		return expected_value


	def likely_future_owners(self, tile, distance=1):
		primitives = [(1, 0), (-1,0), (0,1), (0,-1)]
		primitives *= distance

		operations = itertools.combinations(primitives, distance)

		tiles = set()
		for op in operations:
			row = tile.row
			col = tile.col
			for primitive in op:
				row += primitive[0]
				col += primitive[1]
			t = Tile(row, col)
			tiles.add(t)

		counter = collections.Counter()

		for t in tiles:
			owner = self.game.claims_map.get(t)
			if owner is not None:
				counter[owner] += 1
		

		most_likelys = counter.most_common()

		if len(most_likelys) == 0:
			if distance < 3:
				return self.likely_future_owners(tile, distance + 1)
			else:
				return []
		else:
			max_value = most_likelys[0][1]
			owners = [x[0] for x in most_likelys if x[1] == max_value]
			return owners





	def take_turn(self):
		player = self.player()

	
		move = self.select_move()
		if move is None:
			body = '"PASS"'
		else:
			body = json.dumps({'tile': move.tile.to_json(), 'favor': move.favor})

		for p in self.game.players.values():
			marker = ' '
			if p.id == player.id:
				marker = '*'
			print "|{}{} -> {} ({})".format(marker ,p.name, p.score, p.id)

		if move:
			print "playing", move.tile, move.favor
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
	
	#winner = sorted(players, key=lambda p: p.score, reverse=True)[0]
	#if winner.id == player.id:
	#	print "WINNER"

