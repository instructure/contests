import React from 'react';
import classNames from 'classnames';

import Styles from './Block.css';

export default class Block extends React.Component {
  render() {
    var blockClassNames = classNames(
      Styles.root,
      Styles[this.props.type]
    );
    var blockStyle = {
      top: this.props.y + 'em',
      left: this.props.x + 'em'
    };
    return (
      <div className={blockClassNames} style={blockStyle}></div>
    );
  }
}

Block.propTypes = {
  type: React.PropTypes.string,
  x: React.PropTypes.number,
  y: React.PropTypes.number
};

Block.defaultProps = {
  type: 'I',
  x: 0,
  y: 0
};
