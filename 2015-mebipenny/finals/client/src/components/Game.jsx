import React from 'react';

import Statistic from './Statistic.jsx';
import Canvas from './Canvas.jsx';
import Tetromino from './Tetromino.jsx';

import Styles from './Game.css';

export default class Game extends React.Component {
  state = {
    lines: 0,
    score: 0,
    nextPiece: null,
    isOver: false,
    state: ''
  }

  render() {
    const lines = this.props.lines;
    const score = this.props.score;
    const nextPiece = this.props.nextPiece;
    const isOver = this.props.isOver;
    const state = this.props.state;
    const showRank = this.state.state === 'completed' || this.state.isOver;
    return (
      <div className={Styles.root}>
        <Canvas
          done={this.props.done(() => {
            if (!this.state.isOver) {
              this.setState({lines, score, nextPiece, isOver, state});
            }
          })}
          board={this.props.board}
          isOver={this.props.isOver}
          nextPiece={this.props.nextPiece}
          move={this.props.move}
          rows={this.props.rows}
          cols={this.props.cols}
          />
        <div className={Styles.player} style={{width: this.props.cols + 'em'}}>
          { this.props.player }
        </div>
        { this.state.isOver &&
          <div className={Styles.msg} style={{
            width: this.props.cols + 'em',
            height: this.props.rows + 'em'
          }}>
            Game Over
          </div>
        }
        <div className={Styles.info}>
          <div>
            <Statistic heading="Score" value={this.state.score} />
            <Statistic heading="Lines" value={this.state.lines} />
          </div>
          <div className={Styles.nextPiece}>
            {!showRank && this.state.nextPiece && <Tetromino type={this.state.nextPiece} />}
            {showRank && <div className={Styles.rank}>{this.props.rank}</div>}
          </div>
        </div>
      </div>
    );
  }
}

Game.propTypes = {
  player: React.PropTypes.string.isRequired,
  board: React.PropTypes.array,
  score: React.PropTypes.number,
  lines: React.PropTypes.number,
  nextPiece: React.PropTypes.string,
  isOver: React.PropTypes.bool,
  state: React.PropTypes.string
};

Game.defaultProps = {
  board: 0,
  score: 0,
  lines: 0,
  nextPiece: 'I',
  isOver: false
};
