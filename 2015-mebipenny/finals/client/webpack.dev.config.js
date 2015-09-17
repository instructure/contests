'use strict';

var config = require('./webpack.base.config.js');

config.devServer = {
  contentBase: 'src',
  https: false,
  stats: {
    colors: true
  },
  historyApiFallback: true
};

config.module.loaders = config.module.loaders.concat([
  {
    test: /\.jsx?$/, loaders: [
      'react-hot',
      'babel',
      'babel?optional=runtime'
    ],
    exclude: /node_modules/
  },
  {
    test: /\.css$/,
    exclude: /^(~https?:)?\/\//,
    loader: 'style!css?modules&importLoaders=1&localIdentName=[name]__[local]___[hash:base64:5]!postcss'
  }
]);

module.exports = config;
