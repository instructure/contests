from __future__ import division
from httplib import *
import sys
import argparse
import json
import os
import time
import collections
import itertools



class GameServer:
	def __init__(self, host, port):
		self.conn = HTTPConnection(host, port)
		self.path = ''


	def create_game(self, rows, cols, seats=2, delay=None, coverage=None):
		body = {'rows':rows,'cols':cols, 'seats':seats}
		if delay:
			body['delay_time'] = delay
		if coverage:
			body['seed_coverage'] = coverage

		self.conn.request('POST', '/', json.dumps(body))
		resp = self.conn.getresponse()

		if resp.status != 201:
			body = resp.read()
			raise RuntimeError("Tried to create a game, got response {}, {}".format(resp.status, body))

		loc = resp.getheader('Location')
		print "Created game at {}, copied to clipboard", loc

		out = os.popen('/usr/bin/pbcopy', 'w')
		out.write(loc[1:])
		out.close()

		return loc

	def join_game(self, path, name):
		if path.startswith('/') == False:
			path = '/' + path

		self.path = path

		player_info = {'name':name}
		resp = self.post('/players', json.dumps(player_info))

		if resp.status == 410:
			print "Game full or gone"
			return None

		elif resp.status == 200:
			game_body = json.loads(resp.read())
			game = Game(game_body)
			game.token = resp.getheader("X-Turn-Token")
			print "Joined game"

		else:
			body = resp.read()
			raise RuntimeError("Unexpected response {}, {}".format(resp.status, body))

		return game

	def request_match(self):
		resp = self.get('/match')

		if resp.status != 201:
			body = resp.read()
			raise RuntimeError("Problem requesting match: {}, {}".format(resp.status, body))
		else:
			loc = resp.getheader("Location")
			print "Requested match, got", loc
			return loc

	def post(self, rel_path, body, token=None):
		headers = {}
		if token:
			headers = {'X-Turn-Token': token}
		self.conn.request('POST', self.path + rel_path, body, headers)
		return self.conn.getresponse()

	def get(self, rel_path):
		self.conn.request('GET', self.path + rel_path)
		return self.conn.getresponse()


class Tile:
	def __init__(self, row, col):
		self.row = row
		self.col = col

	@classmethod
	def from_json(cls, data):
		row = data['row']
		col = data['col']
		return cls(row, col)

	def to_json(self):
		data = {'row' : self.row,
		        'col' : self.col }
		return data

	def is_adjacent(self, other):
		if abs(self.row - other.row) == 1 and self.col == other.col:
			return True
		if abs(self.col - other.col) == 1 and self.row == other.row:
			return True
		return False


	def __eq__(self, other):
		return (self.row, self.col) == (other.row, other.col)

	def __cmp__(self, other):
		return cmp((self.row, self.col), (other.row, other.col))

	def __hash__(self):
		return hash((self.row, self.col))

	def __unicode__(self):
		return unicode((self.row, self.col))

	def __repr__(self):
		return "Tile(%s, %s)" % (self.row, self.col)





class Claim:
	def __init__(self, tile, owner):
		self.tile = tile
		self.owner = owner

	@classmethod
	def from_json(cls, data):
		tile = Tile.from_json(data['tile'])
		return cls(tile, data['owner'])

	def __repr__(self):
		return repr(self.tile) + ' -> ' + self.owner


class Player:
	"""
	{id: <string>,
	name: <string>,
	score: <integer> or 'disqualified',
	hand: [<Tile>*] or <integer>}
	"""
	def __init__(self, ID, name, score, hand):
		self.id = ID
		self.name = name
		self.score = score
		self.hand = hand

	@classmethod
	def from_json(cls, data):
		player_id = data['id']
		name = data['name']
		score = data['score']
		if score == 'disqualified':
			score = None

		try:
			hand = [Tile.from_json(x) for x in data['hand']]
		except:
			hand = [None for i in range(data['hand'])]

		return cls(player_id, name, score, hand)



class Game:
	def __init__(self, json_body):
		"""
		  {rows: <integer>,
		   cols: <integer>,
		   draw_size: <integer>,
		   claims: [<Claim>*],
		   players: [<Player>*],
		   state: <Game State>}
		   """
		self.rows = json_body['rows']
		self.cols = json_body['cols']
		self.draw_size = json_body['draw_size']
		claims = [Claim.from_json(x) for x in json_body['claims']]
		self.claims_map = {claim.tile : claim.owner for claim in claims}

		players = [Player.from_json(x) for x in json_body['players']]
		self.players = {player.id : player for player in players}
		self.state = json_body['state']
		self.player_id = json_body['player_id']

	def is_completed(self):
		return self.state == 'completed'

	def update(self, delta):
		self.draw_size = delta.draw_size

		claims_to_update = {claim.tile : claim.owner for claim in delta.claims}
		for tile, owner in claims_to_update.items():
			if owner == None:
				print "Updating a claim to 'none'?"
		self.claims_map.update(claims_to_update)

		players_to_update = {player.id : player for player in delta.players}
		self.players.update(players_to_update)

		self.state = delta.state

	def printBoard(self):
		board = [['-' for x in range(self.cols)] for y in range(self.rows)]

		for tile, owner in self.claims_map.items():
			if owner is None:
				s = '#'
			else:
				s = owner[:1]
			board[tile.row][tile.col] = s

		print ''
		for row in board:
			print '  ' + ''.join(row)
		print ''

	def armiesAdjacentToTile(self, tile):
		up = Tile(tile.row-1, tile.col)
		down = Tile(tile.row+1, tile.col)
		left = Tile(tile.row, tile.col-1)
		right = Tile(tile.row, tile.col+1)

		tiles = [up, down, left, right]
		armies = []

		for tile in tiles:
			already_used = False
			for army in armies:
				if tile in army.claims:
					# Already in a found army, skip it
					already_used = True
			
			if already_used:
				continue

			army = self.armyAtTile(tile)
			if army:
				armies.append(army)

		return armies



	def armyAtTile(self, tile, found=None):
		if found is None:
			found = set()

		if tile in found:
			return Army(found)

		if tile not in self.claims_map or self.claims_map[tile] is None:
			return None

		found.add(tile)

		owner = self.claims_map[tile]

		up = Tile(tile.row-1, tile.col)
		down = Tile(tile.row+1, tile.col)
		left = Tile(tile.row, tile.col-1)
		right = Tile(tile.row, tile.col+1)

		if self.claims_map.get(up) == owner:
			found.update(self.armyAtTile(up, found).claims)

		if self.claims_map.get(down) == owner:
			found.update(self.armyAtTile(down, found).claims)

		if self.claims_map.get(right) == owner:
			found.update(self.armyAtTile(right, found).claims)

		if self.claims_map.get(left) == owner:
			found.update(self.armyAtTile(left, found).claims)

		return Army(found, owner)



class Army:
	def __init__(self, claims, owner=None):
		self.claims = claims
		self.owner = owner


class GameDelta:
	@classmethod
	def from_json(cls, json_body):
		""" {draw_size: <integer>,
		   claims: [<Claim>*],
		   players: [<Player>*],
		   state: <Game State>}"""
		draw_size = json_body['draw_size']
		claims = [Claim.from_json(x) for x in json_body['claims']]
		players = [Player.from_json(x) for x in json_body['players']]
		state = json_body['state']

		self = cls(draw_size, claims, players, state)
		return self

	def __init__(self, draw_size, claims, players, state):
		self.draw_size = draw_size
		self.claims = claims
		self.players = players
		self.state = state


class Move:
	def __init__(self, tile, score, favor, note=None):
		self.tile = tile
		self.score = score
		self.note = note
		self.favor = favor

	def __repr__(self):
		s = "{} -> {}".format(self.tile, self.score)
		if self.note:
			s += '  ({})'.format(self.note)
		return s



def runWithBot(botClass):
	parser = argparse.ArgumentParser(description="Bot for 2012 Mebipenny final problem")
	parser.add_argument('host')
	parser.add_argument('port', type=int)
	group = parser.add_mutually_exclusive_group(required=True)
	group.add_argument('-n', '--new', nargs=2, metavar=('ROWS', 'COLS'), type=int, help="Rows and columns for a new game")
	group.add_argument('-j', '--join', metavar="GAME_PATH", help="Path to the game on the server", dest='path')
	group.add_argument('-m', '--match', action='store_true', help="Request the next available game from the server")

	newgame_group = parser.add_argument_group("New game options", "These options only apply to manually created new games")
	newgame_group.add_argument('-d', '--delay', type=float, metavar='N', help="Adds a delay of N seconds after every turn")
	newgame_group.add_argument('-s', '--seats', type=int, default=2, help="Number of seats in the game")
	newgame_group.add_argument('-c', '--coverage', type=float, help="Percent of board to seed with walls")

	parser.add_argument('player_name')

	args = parser.parse_args()
	server = GameServer(args.host, args.port)

	if args.new:
		rows, cols = args.new
		path = server.create_game(rows, cols, args.seats, args.delay, args.coverage)
	elif args.path:
		path = args.path
	else:
		path = server.request_match()

	name = args.player_name + '_' + botClass.name

	game = server.join_game(path, name)
	game_player = game.players[game.player_id]

	bot = botClass(server, game, game_player.id)
	while not game.is_completed():
		game.printBoard()
		bot.take_turn()

	players = game.players.values()

	player_scores = collections.Counter(game.claims_map.values())

	for player in players:
		score = player_scores[player.id]
		marker = ''
		if player.id == game_player.id:
			marker = ' *'
		print "{}{} -> {}".format(player.name, marker, score)

if __name__ == "__main__":
	print "This file should not be run directly. Import it into other files."


	#winner = sorted(players, key=lambda p: p.score, reverse=True)[0]
	#if winner.id == player.id:
	#	print "WINNER"

