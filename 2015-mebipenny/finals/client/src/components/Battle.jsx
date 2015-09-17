import React from 'react';
import Match from './Match.jsx';
import client from '../lib/client';
import Immutable from 'immutable';
import QueryString from 'query-string';

import Styles from './Battle.css';

export default class Battle extends React.Component {
  state = {
    games: new Immutable.OrderedMap()
  };

  componentDidMount () {
    var gameId = QueryString.parse(window.location.search).gameId || '*';

    var channel = `/${process.env.PANDA_PUSH_APP_ID}/public/games/${gameId}`;

    this.subscription = client.subscribe(channel, game => {
      const gameState = Immutable.fromJS(game);
      this.setState({ games: this.state.games.set(game.id, gameState) });
    });
  }

  shouldComponentUpdate(nextProps, nextState) {
    return this.state.games !== nextState.games;
  }

  render() {
    return (
      <div className={Styles.root}>
        {
          this.state.games.reverse().map(game =>
            <Match
              key={game.get('id')}
              id={game.get('id')}
              players={game.get('players')}
              nextPiece={game.get('current_piece')}
              rows={game.get('rows')}
              cols={game.get('cols')}
              state={game.get('state')}
              disqualified={game.get('disqualified')}
            />
          ).toList()
        }
      </div>
    );
  }
}
