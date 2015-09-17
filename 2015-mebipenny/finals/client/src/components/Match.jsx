import React from 'react';
import Immutable from 'immutable';

import Game from './Game.jsx';

import Styles from './Match.css';

export default class Match extends React.Component {
  shouldComponentUpdate(nextProps) {
    return this.props.players !== nextProps.players;
  }

  syncUpdate(...players) {
    const done = new WeakSet();
    const resolves = [];
    return player => fn => () => {
      fn(player);
      done.add(player);
      return new Promise(resolve => {
        resolves.push(resolve);
        if (players.every(p => done.has(p))) {
          resolves.forEach(r => r());
        }
      });
    };
  }

  shouldComponentUpdate(nextProps) {
    return this.props.players !== nextProps.players;
  }

  getRank(player) {
    const disqualifiedIndex = this.props.disqualified.indexOf(player.id);
    if (disqualifiedIndex > -1) {
      return this.props.players.size - disqualifiedIndex;
    }
    return this.props.players
      .sortBy(p => p.get('score'))
      .reverse()
      .map(p => p.get('score'))
      .indexOf(player.score) + 1;
  }

  render() {
    const players = this.props.players.toJS();
    const update = this.syncUpdate(...players);
    return (
      <div className={Styles.root}>
        { players.map(player => (
          <Game
            key={player.id}
            player={player.name}
            done={update(player)}
            board={player.board}
            lines={player.lines}
            score={player.score}
            rank={this.getRank(player)}
            move={player.last_move}
            nextPiece={this.props.nextPiece}
            isOver={player.disqualified}
            state={this.props.state}
            rows={this.props.rows}
            cols={this.props.cols}
          />
        )) }
        {
          this.props.state === 'initiating' &&
          <div className={Styles.msg}>
            /{this.props.id}
          </div>
        }
      </div>
    );
  }
}

Match.propTypes = {
  players: React.PropTypes.instanceOf(Immutable.List).isRequired,
  nextPiece: React.PropTypes.string.isRequired,
  id: React.PropTypes.string.isRequired,
  state: React.PropTypes.string.isRequired
};
