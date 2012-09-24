MebiPenny 2012 Final
====================

Write a JSON REST API client to play a game.

server/ contains the server code. bj/ and simon/ contain some example
bots written by Instructure employees. viz/ contains our visualization
tool.

## Game Description ##

The game is played on a rectangular field which starts empty. Each space
on the field has a corresponding tile in a randomized "draw" pile. Each
player starts with 6 tiles drawn from this pool in their "hand". Player
order is determined randomly.

On a player's turn, they either pass or select one of the tiles from
their hand to play. If they play a tile, they draw a new one at the end
of their turn to replace it; a player's hand will always have 6 tiles
until the draw is exhausted, at which point hands will begin to dwindle.
Once a player's hand is empty (because the draw is empty and they've
played all tiles in their hand) they must pass. The game ends when all
players pass consecutively.

Any contiguous region of tiles in the playing field forms an army of a
single player, representing the controlling player. When a tile is
played, it becomes part of an army. The other members of the tile's army
(if any) may have belonged to multiple colors; the color of the new army
is determined by the majority representation in the absorbed regions.
For the purpose of determining majority, the new tile counts as the
color of the player and ties are decided by the player.

The player with the most territory at the end of the game wins.

### Example Plays ###

All plays are assumed made by the red player.

* Playing a single tile with no neighbors creates a 1-tile red army.
* Playing a tile whose only neighbor is a 1-tile blue army creates a
  2-tile army. The new army is either red or blue, red player's choice.
* Playing a tile that joins two red armies creates one larger red army.
* Playing a tile that joins two blue armies creates one larger blue
  army.
* Playing a tile that joins a 5-tile blue army and a 3-tile red army
  creates a 9-tile blue army.
* Playing a tile that joins a 5-tile blue army and a 5-tile red army
  creates an 11-tile red army.
* Playing a tile that joins a 5-tile blue army and a 4-tile red army
  creates an 10-tile army. The new army is either red or blue, red
  player's choice.
* Playing a tile that joins a 1-tile blue army and a 1-tile green army
  creates a 3-tile army. The new army is either red, blue, or green, red
  player's choice.

## Communication ##

All request and response payloads are serialized JSON data.

## Data Types ##

### New Player (request) ###

    {name: <string>}

name of the new player.

### Player (response) ###

    {id: <string>,
     name: <string>,
     score: <integer> or 'disqualified',
     hand: [<Tile>*] or <integer>}

id is a unique, opaque string identifying the player.

name and current score of the player.

when sent to the player, hand is the list of tile coordinates in the
player's hand; otherwise, it is the number of tiles in the player's
hand.

### New Game (request) ###

    {rows: <integer>,
     cols: <integer>,
     seats: <integer>}

rows and cols define the new board size and are required.

seats define the number of players for the game. must be between 2 and 4
if provided; defaults to 2 if absent.

### Game (response) ###

    {rows: <integer>,
     cols: <integer>,
     draw_size: <integer>,
     claims: [<Claim>*],
     players: [<Player>*],
     player_id: <string>,
     state: <Game State>}

rows and cols define the board size.

draw_size is the number of tiles remaining in the draw pool.

claims is the set of Claims already present on the board.

players is the set of Players joined to the game.

player_id is your player id, or null if you are an observer.

state is the current Game State.

### Game Delta (response) ###

    {draw_size: <integer>,
     claims: [<Claim>*],
     players: [<Player>*],
     state: <Game State>}

draw_size is the number of tiles remaining in the draw pool. will be
present even if the value did not change since the request began.

claims is the set of changed Claims on the board since the request
began. a Claim may have changed by being played or by being changing
ownership.

players is the set of Players whose scores have changed since the
request began, or whose hand size/contents (depending on visibility)
have changed.

state is the current Game State.

### Game State (response) ###

    'initiating', 'in play', or 'completed'

See descriptions of game states below.

### New Move (request) ###

    { tile: <Tile>,
      favor: <string> }

or

    "PASS"

the string "PASS" indicates the player passes on this turn.

tile is the Tile to play on the board. it must be previously unclaimed
and in the player's hand.

favor is the ID of the player to favor when breaking ties for captures.
if absent, it is assumed to be the active player. if there is not tie to
be broken, it is ignored. if there is a tie, and favor does not identify
one of the players involved in the tie, the move is considered illegal
(malformed).

### Tile (response) ###

    {row: <integer>,
     col: <integer>}

### Claim (response) ###

    {tile: <Tile>,
     owner: <string>}

Represents a claimed Tile on the board. owner is the player's unique,
opaque ID string.

a Claim with no owner indicates a terrain feature which should be
treated as a wall. these claims, if any, will be placed on the board
during setup and cannot be captured by nor capture other armies. tiles
for these locations are removed from the draw on setup.

## STARTING A GAME ##

To spawn a new game on the server, POST to / with a New Game object as
payload.  You will receive a 201 Created response with the game's root
path (henceforth &lt;game path&gt;) in the Location HTTP response
header.

## GAME STATES ##

### INITIATING ###

The game begins in this state. You join a game by POSTing to &lt;game
path&gt;/players with a New Player object as payload.

If you successfully join the game, you will receive a 200 OK response at
the beginning of your first turn, with a Game object as response
payload. This response will include an X-Turn-Token HTTP response
header.

If the game is no longer in this state (i.e. it is full and has already
started) when you POST, you will receive a 410 Gone response indicating
the game can no longer be joined.

Once the game is full the game moves to the in play state.

### IN PLAY ###

In this state, players POST to &lt;game path&gt;/moves with New Move
objects as payload. These requests must include an X-Turn-Token HTTP
request header with the value of the last turn token they received from
the server.

After receiving a 200 OK response to a &lt;game path&gt;/players or
&lt;game path&gt;/moves POST request (indicating it is your turn) you
are required to POST your next move within 30 seconds. If you fail to
POST in that time, you are disqualified and the game moves to the
completed state.

If the move POSTed is illegal, you will receive an immediate 403
Forbidden response describing the violation. You are disqualified and
the game moves to the completed state.

Otherwise, you will receive a 200 OK response at the beginning of your
next turn, with a Game Delta object. This response will include an
X-Turn-Token response header to be used in your next move.

After a 200 OK response, the game may have moved to the completed state.
This state change will be indicated in the Game Delta object. Once the
game is completed, further moves are ignored with a 410 Gone response.

### COMPLETED ###

Play is complete. Game state can still be pulled, but no new POSTs are
accepted.

## IDEMPOTENT VIEW ##

At any point, the full game state can be requested with a GET request to
&lt;game path&gt;. You will receive an immediate 200 OK response with a
Game object.

## OBSERVERS ##

(Intended for use by game viewer, but may be used by others.)

At any point, an observer may be registered by POSTing to &lt;game
path&gt;/observers. This will begin a long-running unbounded HTTP
response of type application/x-multi-json , which is a series of
one-line json documents separated by newlines.

You will receive an immediate 200 OK response with the first document, a
Game object.  After this, the response will remain open and new Game
Delta objects will be returned as events occur.

The HTTP response will end when the game ends, after the final Game
Delta object is sent.

The POST request requires no payload. However, if the payload includes a
"wrapper" key, then each JSON document will be fprint'ed into that text,
replacing the first %s. For instance, a HTML comet technique:

    { "wrapper": "<script type='text/javascript'>myUpdater(%s);</script>\n" }

## MATCHMAKING ##

When you have a bot you'd like to try against others, but you don't want
to set up a game yourself and you don't care who your opponent is, you
can connect your bot to our dirt-simple (and stupid) matchmaking system.

Simply GET /match and wait for a response. You will be added to a
matchmaking queue, and once there are at least two people in the queue,
the front two will be popped and each given a 302 Redirect with a game's
url in the Location HTTP response header.

If no one else is joining, feel free to request a match against any of
our bots! (Our bots are not eligible to win, so don't worry.)
