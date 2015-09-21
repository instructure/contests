# Stringham's bots

## Setup

run

```bash
$ npm install
```

in this directory to install the dependencies

## Running bots

```bash
$ node bot_v1.js
```

will run the bot with default paramaters (on the public server, create a game with 1 seat and immediately join and play).

options include:

    --name
    --size
    --host
    --location


if no location is provided then it creates a game with `--size` seats, if a location is provided it attempts to join the game at the given location.

## Bots

Both bots follow a similar strategy of looking at all possible rotations/positions of the next 2 pieces to decide where to place the current piece. After placing the pieces they score the resulting board and make the move that minimizes the score.

### bot_v1.js

This is the bot that was used to win the finals of the Mebipenny.

The heuristics in the scoring function attempts to minimize the number of holes, where a hole is an unocupied space below another block, since we can't slide pieces in.

It avoids playing near the top of the board and rewards moves that remove lines.

It penalizes building deep crevises where the only piece that could fit in is an `I`.

Lastly, it favors dropping the piece in a lower location if all else is equal.

### bot_v2.js

This bot consistently beats v1. It counts the number of edges created by the pieces and minimizes that. An edge is when there is an empty space next to a block. Edges on the bottom and sides are not counted.

For example:


    |x      |
    |xx xx  |
    |xxxxxx |
    ---------

has 11 edges.

It penalizes growing the board too high and avoid creating holes. It prefers placing pieces lower if all else is equal.