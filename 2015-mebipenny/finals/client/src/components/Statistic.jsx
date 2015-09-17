import React from 'react';

import Styles from './Statistic.css';

export default class Statistic extends React.Component {
  render () {
    return (
      <div className={Styles.root}>
        <div className={Styles.border}>
          <div className={Styles.heading}>
            { this.props.heading }
          </div>
          <div className={Styles.value}>
            { this.props.value }
          </div>
        </div>
      </div>
    );
  }
}

Statistic.propTypes = {
  heading: React.PropTypes.string.isRequired,
  value: React.PropTypes.number.isRequired
};
