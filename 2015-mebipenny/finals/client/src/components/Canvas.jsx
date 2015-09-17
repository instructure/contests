import React from 'react';
import Immutable from 'immutable';
import chan from 'chan';
import equal from 'deep-equal';

import * as tile from '../lib/tile.js';
import animate from '../lib/animate.js';

import styles from './Canvas.css';

function easeOutQuad(t, b, c, d) {
  t /= d;
  return -c * t * (t - 2) + b;
}

function copyCtx(ctx, blank) {
  const copy = document.createElement('canvas').getContext('2d');
  copy.canvas.width = ctx.canvas.width;
  copy.canvas.height = ctx.canvas.height;
  if (!blank) {
    copy.drawImage(ctx.canvas, 0, 0);
  }
  return copy;
}

export default class BoardCanvas extends React.Component {
  constructor() {
    super();
    this.animationQueue = chan();
  }

  animatePiece = (move, key) => {
    return async () => {
      if (!move) {
        return;
      }
      await tile.imagesLoaded;
      const piece = copyCtx(this.ctx, true);
      move.forEach(cell => {
        tile.drawTo(piece, key, cell.col, this.props.rows - cell.row - 1);
      });
      const copy = copyCtx(this.ctx);
      const start = piece.canvas.height * -1;
      await animate(start, 0, 200, easeOutQuad, val => {
        this.clear();
        this.ctx.drawImage(copy.canvas, 0, 0);
        this.ctx.drawImage(piece.canvas, 0, val);
      });
    };
  };

  animateLine = (offset) => {
    return async () => {
      const w = this.props.cols * tile.SIZE;
      const h = this.props.rows * tile.SIZE;
      const l = (this.props.rows - 1 - offset) * tile.SIZE;
      const above = copyCtx(this.ctx);
      above.clearRect(0, l, w, h - l);
      const line = copyCtx(this.ctx, true);
      line.drawImage(this.ctx.canvas, 0, l, w, tile.SIZE, 0, l, w, tile.SIZE);
      const below = copyCtx(this.ctx);
      below.clearRect(0, 0, w, l + tile.SIZE);
      await animate(0, w, 150, easeOutQuad, val => {
        this.clear();
        this.ctx.drawImage(above.canvas, 0, 0);
        this.ctx.drawImage(below.canvas, 0, 0);
        this.ctx.drawImage(line.canvas, val, 0);
      });
      await animate(0, tile.SIZE, 100, easeOutQuad, val => {
        this.clear();
        this.ctx.drawImage(above.canvas, 0, val);
        this.ctx.drawImage(below.canvas, 0, 0);
      });
    };
  }

  animateFinal = (board, garbage = 0) => {
    return async () => {
      await tile.imagesLoaded;
      const canvas = document.createElement('canvas');
      canvas.width = this.ctx.canvas.width;
      canvas.height = this.ctx.canvas.height;
      const ctx = canvas.getContext('2d');
      board.forEach((row, y) => {
        row.forEach((cell, x) => {
          if (cell != null) {
            tile.drawTo(ctx, cell, x, this.props.rows - 1 - y);
          }
        });
      });
      await animate(garbage * tile.SIZE, 0, garbage * 100, easeOutQuad, val => {
        this.clear();
        this.ctx.drawImage(canvas, 0, val);
      });
    };
  }

  componentDidMount() {
    this.ctx = this.refs.canvas.getDOMNode().getContext('2d');
    this.previouseBoard = this.props.board;
    this.loop();
    this.animationQueue(null, this.animateFinal(this.props.board));
  }

  shouldComponentUpdate(nextProps) {
    if (nextProps.isOver) {
      this.animationQueue(null, nextProps.done);
      return false;
    }
    return !equal(this.props.move, nextProps.move);
  }

  componentWillUpdate(nextProps) {
    const key = this.props.nextPiece;
    this.animationQueue(null, this.animatePiece(nextProps.move, key));
    let totalRemoved = 0;
    const board = Immutable.fromJS(this.props.board).withMutations(b => {
      nextProps.move.forEach(cell => b.setIn([cell.row, cell.col], key));
    });
    const lines = board
      .filter(row => row.every(cell => cell != null))
      .map(row => board.indexOf(row));
    lines.forEach((line, i) => {
      this.animationQueue(null, this.animateLine(line - i));
    });
    const ph = board.findLastIndex(row => row.first() !== null);
    const nextBoard = Immutable.fromJS(nextProps.board);
    const nh = nextBoard.findLastIndex(row => row.first() !== null);
    const garbage = nh - ph - lines.size;
    this.animationQueue(null, this.animateFinal(nextProps.board, garbage));
    this.animationQueue(null, nextProps.done);
  }

  componentWillUnmount() {
    this.animationQueue.close();
  }

  loop() {
    const handler = async (err, step) => {
      if (err) {
        console.error(err);
      } else if (step !== this.animationQueue.empty) {
        await step();
      }
      if (!this.animationQueue.done()) {
        this.animationQueue(handler);
      }
    };
    this.animationQueue(handler);
  }

  clear(ctx) {
    ctx = ctx || this.ctx;
    this.ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
  }

  render() {
    const rootStyle = {
      width: (this.props.cols + 2) + 'em',
      height: this.props.rows + 'em'
    };
    return (
      <div className={styles.root} style={rootStyle}>
        <canvas
          ref="canvas"
          className={styles.board}
          width={this.props.cols * tile.SIZE}
          height={this.props.rows * tile.SIZE}
          style={{flex: this.props.cols}}
        />
      </div>
    );
  }
}

BoardCanvas.propTypes = {

};
