'use strict';

var ExtractTextPlugin = require('extract-text-webpack-plugin');

var production = process.env.NODE_ENV === 'production';
var config = production ? require('./webpack.prod.config.js') : require('./webpack.base.config.js');

config.module.loaders = config.module.loaders.concat([
  {
    test: /\.jsx?$/,
    loader: 'babel?optional=runtime',
    exclude: /node_modules/
  },
  {
    test: /\.css$/,
    exclude: /^(https?:)?\/\//,
    loader: ExtractTextPlugin.extract(
      'style',
      'css?modules&importLoaders=1&localIdentName=[name]__[local]___[hash:base64:5]!postcss'
    )
  }
]);

config.plugins = config.plugins.concat(
  [
    new ExtractTextPlugin(config.output.css)
  ]
);

module.exports = config;
