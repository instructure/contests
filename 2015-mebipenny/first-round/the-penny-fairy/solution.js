#!/usr/bin/env node

readStdin = function(callback) {
  var data = "";
  process.stdin.resume();
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', function(chunk) {
    return data += chunk.toString();
  });
  return process.stdin.on('end', function() {
    var lines = data.split(/\n/);
    var yesterday = parseInt(lines[0]);
    var current = parseInt(lines[1]);
    var max = parseInt(lines[2]);

    var factor = current / yesterday
    var i = 0
    while (current < max) {
      i++;
      current = Math.ceil(current * factor);
    }
    console.log(i);
  });
};

readStdin();
