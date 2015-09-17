import React from 'react';
import Block from './Block.jsx';

import Styles from './Well.css';

const Theme = require('../config/theme.json');

export default class Well extends React.Component {
  render() {
    var board = this.props.board;
    var blocks = board.map((row, y) => {
      return row.map((col, x) => {
        var transposedY = (Theme['board-rows'] - 1) - y;
        return col ? <Block type={col} x={x} y={transposedY} /> : null;
      });
    });
    return (
      <div className={Styles.root}>
        <div className={Styles.blocks}>
          { blocks }
        </div>
      </div>
    );
  }
}

Well.propTypes = {
  board: React.PropTypes.array
};

Well.defaultProps = {
  board: []
};
