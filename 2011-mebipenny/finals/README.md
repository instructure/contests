All request and response payloads are serialized JSON data.

= DATA TYPES

== New Player (request)

  {name: <string>}

name of the new player.

== Player (response)

  {name: <string>,
   score: <integer> or 'disqualified'}

name and current score of the player.

== New Game (request)

  {rows: <integer>,
   cols: <integer>}

rows and cols defined the new board size. rows must be odd and ≥ 3. cols will
always be ≥ 3 and represents the number of Coordinates per odd row. The number
of Coordinates per event row will equal cols - 1. The first row is index 0 and
therefore even, second row is odd, etc.

== Game (response)

  {rows: <integer>,
   cols: <integer>,
   lines: [<Line>*],
   hexagons: [<Hexagon>*],
   players: [<Player>*],
   state: <Game State>}

rows and cols define the board size.

lines is the set of Lines already placed on the board.

hexagons is the set of Hexagons already claimed on the board.

players is the set of Players joined to the game.

state is the current Game State.

== Game Delta (response)

  {lines: [<Line>*],
   hexagons: [<Hexagon>*],
   players: [<Player>*],
   state: <Game State>}

lines is the set of new Lines placed on the board since the request began.

hexes is the set of new Hexagons claimed on the board since the request began.

players is the set of Players whose scores have changed since the request
began.

state is the current Game State.

== Game State (response)

  'initiating', 'in play', or 'completed'

See descriptions of game states below.

== New Line (request)

  [<Coordinate>, <Coordinate>]

Coordinates in requests may be in arbitrary order, but must be adjacent.

== Line (response)

  {endpoints: [<Coordinate>, <Coordinate>]
   owner: <Player>}

Represents a line between the two endpoint Coordinates. Coordinates in
responses will always be sorted in row-major order (Coordinates are sorted by
row, then Coordinates with the same row are sorted by col).

Owner is the player that placed the line.

== Hex (response)

  {center: <Coordinate>,
   owner: <Player>}

Represents a claimed Hexagon on the board. The six triangles surrounding the
center Coordinate are assigned to the owner.

== Coordinate (request or response)

  {row: <integer>,
   col: <integer>}

= STARTING A GAME

To spawn a new game on the server, POST to / with a New Game object as payload.
You will receive a 201 Created response with the game's root path (henceforth
<game path>) in the Location HTTP response header.

= GAME STATES

== INITIATING

The game begins in this state. You join a game by POSTing to
<game path>/players with a Player object as payload.

If you are one of the first two players to join the game, you will receive a
200 OK response at the beginning of your first turn, with a Game object as
response payload. This response will include an X-Turn-Token HTTP response
header.

If the game is no longer in this state (i.e. two players had already joined)
when you POST, you will receive a 410 Gone response indicating the game can no
longer be joined.

Once two players have posted a join request the game moves to the in play
state.

== IN PLAY

In this state, players POST to <game path>/moves with Line objects as payload.
These requests must include an X-Turn-Token HTTP request header with the value
of the last turn token they received from the server.

After receiving a 200 OK response to a <game path>/players or <game path>/moves
POST request (indicating it is your turn) you are required to POST your next
move within {{time limit}}. If you fail to POST in that time, you are
disqualified and the game moves to the completed state.

If the move POSTed is illegal, you will receive an immediate 403 Forbidden
response describing the violation. You are disqualified and the game moves to
the completed state.

If the move POSTed completes a Hexagon, you will receive an immediate 200 OK
response, with a Game Delta object. This response will include an X-Turn-Token
response header to be used in your next move.

Otherwise, you will receive a 200 OK response at the beginning of your next
turn, with a Game Delta object. This response will include an X-Turn-Token
response header to be used in your next move.

After a 200 OK response, the game may have moved to the completed state. This
state change will be indicated in the Game Delta object. Once the game is
completed, further moves are ignored with a 410 Gone response.

== COMPLETED

Play is complete. Game state can still be pulled, but no new POSTs are
accepted.

= IDEMPOTENT VIEW

At any point, the full game state can be requested with a GET request to
<game path>. You will receive an immediate 200 OK response with a Game object.

= OBSERVERS

(Intended for use by game viewer, but may be used by others.)

At any point, an observer may be registered by POSTing to <game
path>/observers. This will begin a long-running unbounded HTTP response of
type application/x-multi-json , which is a series of one-line json
documents separated by newlines.

You will receive an immediate 200 OK response with the first document, a
Game object.  After this, the response will remain open and new Game Delta
objects will be returned as events occur.

The HTTP response will end when the game ends, after the final Game Delta
object is sent.

The POST request requires no payload. However, if the payload includes a
"wrapper" key, then each JSON document will be fprint'ed into that text,
replacing the first %s. For instance, a HTML comet technique:

    { "wrapper": "<script type='text/javascript'>myUpdater(%s);</script>\n" }

= MATCHMAKING

When you have a bot you'd like to try against others, but you don't want to set
up a game yourself and you don't care who your opponent is, you can connect
your bot to our dirt-simple (and stupid) matchmaking system.

Simply GET /match and wait for a response. You will be added to a matchmaking
queue, and once there are at least two people in the queue, the front two will
be popped and each given a 302 Redirect with a game's url in the Location HTTP
response header.

If no one else is joining, feel free to request a match against any of our
bots! (Our bots are not eligible to win, so don't worry.)
