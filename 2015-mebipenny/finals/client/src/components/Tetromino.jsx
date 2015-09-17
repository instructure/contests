import React from 'react';
import classNames from 'classnames';

import Block from './Block.jsx';

import Styles from './Tetromino.css';

// define shape rotations (http://tetris.wikia.com/wiki/SRS)
const SHAPES = {
  I: [
    [1, 1, 1, 1]
  ],
  O: [
    [1, 1],
    [1, 1]
  ],
  T: [
    [0, 1, 0],
    [1, 1, 1]
  ],
  J: [
    [1, 0, 0],
    [1, 1, 1]
  ],
  L: [
    [0, 0, 1],
    [1, 1, 1]
  ],
  S: [
    [0, 1, 1],
    [1, 1, 0]
  ],
  Z: [
    [1, 1, 0],
    [0, 1, 1]
  ]
};

export default class Tetromino extends React.Component {
  render() {
    var tetrominoClassNames = classNames(
      Styles.root,
      Styles[this.props.type]
    );
    var shape = SHAPES[this.props.type];
    var blocks = shape.map((row, y) => {
      return row.map((col, x) => {
        return col ? <Block type={this.props.type} x={x} y={y} /> : null;
      });
    });
    return (
      <div className={tetrominoClassNames}>
        { blocks }
      </div>
    );
  }
}

Tetromino.propTypes = {
  type: React.PropTypes.string
};

Tetromino.defaultProps = {
  type: 'I'
};
