var http = require('http');
var $ = require('jquery-deferred');
var https = require('https');
var nconf = require('nconf');

nconf.argv();
nconf.file('config.json');
nconf.defaults({
	'name': 'stringham v2',
	'host': 'pajitnov.inseng.net',
	'size': 1,
	'location': ''
});

var HOST = nconf.get('host');
var NAME = nconf.get('name');
var GAME_SIZE = nconf.get('size');
var LOCATION = nconf.get('location');

function mixin(target, source){
	for (var x in source) {
	  target[x] = source[x];
	}
}


function makeRequest(_options, tryNum, deferred){
	deferred =  deferred || $.Deferred();
	tryNum = tryNum || 0;

	var options = {
		https:false,
		method:'GET',
		host:HOST,
		port: 80,
		path:'',
		headers: {}
	}
	mixin(options, _options || {});

	var postData = '';
	if(options.data){
		postData = JSON.stringify(options.data);
	}

	if(options.method != 'GET'){
		options.headers['Content-Length'] = postData.length;
	}
	options.headers['Content-type'] = 'application/json';

	var protocol = options.https ? https : http;

	var request = protocol.request(options, function(res){
		var output = '';
		var headers = res.headers;

		res.on('data', function(chunk){
			output+=chunk;
		});

		res.on('end', function(){
			var result;
			try{
				result = output.length > 0 ? JSON.parse(output) : '';
			} catch(e){
				console.error('failed to parse response', output);
				result = output;
			}
			deferred.resolve(result, headers);
		});
	});
	if(options.method == 'PUT' || options.method == 'POST'){
		request.write(postData);
	}
	request.on('error', function(e){
		console.log(JSON.stringify(options,2));
		console.log(JSON.stringify(e));
		console.error('request error', e);
		if(tryNum > 10){
			deferred.reject(e);
		} else {
			setTimeout(function() {
				makeRequest(options, tryNum+1, deferred);
			}, 1000*(tryNum+1));
		}
	});

	request.setTimeout(1000000000);
	request.end();

	return deferred.promise();
}

function createGame(seats){
	var data = {
		seats:seats,
		initial_garbage:0
	};
	makeRequest({
		data:data,
		method:'POST',
		path:'/'
	}).then(function(result, headers){
		joinGame(headers.location);
	});
}

function joinGame(location){
	console.log('joining game', location);
	makeRequest({
		path:location + '/players',
		method:'POST',
		data:{
			name:NAME
		},
	}).then(function(result, headers){
		startGame(result,headers, location);
	});
}

function startGame(result, headers, location){
	var playerId = headers['x-player-id'];
	var turnToken = headers['x-turn-token'];


	play(result, location, turnToken, playerId);
}

function play(state, location, turnToken, playerId){
	printBoard(getMyPlayer(state,playerId), location);
	var move = getMove(state, playerId, location);
	console.log('sending move',state.current_piece);
	makeMove(move, location, turnToken, playerId).then(function(state, headers){
		var nextToken = headers['x-turn-token'];
		play(state, location, nextToken, playerId)
	});
}

function makeMove(move, location, turnToken, playerId){
	return makeRequest({
		method:'POST',
		path:location +'/moves',
		data:move,
		headers:{
			'x-turn-token':turnToken
		}
	})
}


function getMyPlayer(state, id){
	for(var i=0; i<state.players.length; i++){
		if(state.players[i].id == id){
			return state.players[i];
		}
	}
}

function getMyBoard(state, id){
	return getMyPlayer(state,id).board;
}

function rotated(piece){
	var result = [];
	for(var i=0; i<piece[0].length; i++){
		var current = [];
		for(var j=0; j<piece.length; j++){
			current.push(piece[j][i]);
		}
		current.reverse();
		result.push(current);
	}
	return result;
}

var pieces = {
 'I':[['x'],
      ['x'],
      ['x'],
      ['x']],
 'L':[[' ','x'],
 	  [' ','x'],
      ['x','x']],
 'J':[['x',' '],
 	  ['x',' '],
      ['x','x']],
 'O':[['x','x'],
      ['x','x']],
 'Z':[['x',' '],
 	  ['x','x'],
      [' ','x']],
 'T':[['x',' '],
 	  ['x','x'],
      ['x',' ']],
 'S':[[' ','x'],
 	  ['x','x'],
      ['x',' ']]
};

function printBoard(player, location){

	var board = player.board;
	var score = player.score;
	var lines = player.lines;
	console.log('Score: ' + score + '    lines: ' + lines);
	console.log('game id: http://'+HOST+'/public/?gameId=' +location.substr(1));

	console.log('--'+board[0].map(function(p){return '-'}).join(''))
	for(var row = board.length-1; row>=0; row--){
		console.log('|'+board[row].map(function(p){
			if(p == null){
				return ' '
			}
			return 'x';
		}).join('')+'|');
	}
	console.log('--'+board[0].map(function(p){return '-'}).join(''))
}

function getMove(state, playerId, location){
	var board = getMyBoard(state, playerId);

	var currentPiece = state.current_piece;
	var nextPiece = state.next_piece;

	var piece = pieces[currentPiece];
	var next = pieces[nextPiece];

	var minScore = Infinity;
	var move = null;
	for(var r=0; r<4; r++){
		for(var i=0; i<board[0].length-piece[0].length+1; i++){
			var potential = dropPiece(board, piece, i);
			var boardWithPiece = getUpdatedBoard(board, potential.locations);
			
			for(var a=0; a<4; a++){
				for(var j=0; j<board[0].length-next[0].length+1; j++){
					var potential2 = dropPiece(boardWithPiece, next, j);
					var boardWith2Pieces = getUpdatedBoard(boardWithPiece, potential2.locations);
					var score = scoreBoard(boardWith2Pieces, potential.locations);
					if(score < minScore || (score == minScore && Math.random() < 0.4)){
						minScore = score;
						move = potential;
					}
				}
				next = rotated(next);
			}
		}
		piece = rotated(piece);
	}

	return move;

}

function copyBoard(board){
	var result = [];
	for(var i=0; i<board.length; i++){
		var row = [];
		for(var j=0; j<board[i].length; j++){
			row.push(board[i][j]);
		}
		result.push(row);
	}
	return result;
}

function getUpdatedBoard(board, locations){
	var copied = copyBoard(board);
	var height = board.length;
	locations.forEach(function(l){
		if(l.row < height)
			copied[l.row][l.col] = 'x';
	});
	return removeFullRows(copied);
}

function removeFullRows(board){
	var result = [];
	for(var i=0; i<board.length; i++){
		if(!isFull(board[i]))
			result.push(board[i]);
	}
	return result;
}

function isFull(row){
	return !row.some(function(a){
		return a == null;
	});
}

var heightValues = [0,0,0,0,0,0,0,1,1,1,1,2,2,2,3,3,4,4,5,6,7,8,9,10,11];

function scoreBoard(board, piece){
	var maxPieceRow = Math.max.apply(null, piece.map(function(p){return p.row}))
	var averagePieceRow = getAverage(piece.map(function(l){return l.row}));

	if(maxPieceRow >= board.length){
		return Infinity;
	}
	return edgeCount(board) + getEmptySpaces(board) + 2*blockageFromHighestEmptySpace(board) + averagePieceRow + heightValues[Math.max.apply(null, getColumnHeights(board))];
}

function edgeCount(board){
	var count = 0;
	for(var i=0; i<board.length; i++){
		for(var j=0; j<board[i].length-1; j++){
			if((board[i][j] && !board[i][j+1]) || (!board[i][j] && board[i][j+1])){
				count++;
			}
		}
	}
	for(var j=0; j<board[0].length; j++){
		for(var i=0; i<board.length-1; i++){
			if((board[i][j] && !board[i+1][j]) || (!board[i][j] && board[i+1][j])){
				count++;
			}
		}
	}
	return count;
}

function getEmptySpaces(board){
	var total = 0;
	for(var col=0; col < board[0].length; col++){
		var inEmptyLand = false;
		for(var row=board.length-1; row>=0; row--){
			if(board[row][col] == null && inEmptyLand){
				total++;
			}
			if(board[row][col] != null){
				inEmptyLand = true;
			}
		}
	}
	return total;
}

function getAverage(n){
	return n.reduce(function(a,b){return a+b;}, 0)/n.length;
}

function blockageFromHighestEmptySpace(board){
	var highestEmptySpaceRow = -1;
	var highestEmptySpaceCol = -1;;
	for(var col=0; col < board[0].length; col++){
		var inEmptyLand = false;
		for(var row=board.length-1; row>=0; row--){
			if(!board[row][col] && inEmptyLand){
				if(row >highestEmptySpaceRow){
					highestEmptySpaceRow = row;
					highestEmptySpaceCol = col;
				}
			}
			if(board[row][col]){
				inEmptyLand = true;
			}
		}
	}

	var count = 0;
	if(highestEmptySpaceRow >= 0){
		for(var i=highestEmptySpaceRow+1; i<board.length; i++){
			if(board[i][highestEmptySpaceCol]){
				count++;
			}
		}
	}
	return count + Math.max(0,highestEmptySpaceRow);
}

function getPieceDepth(piece){
	var result = [];
	for(var i=0; i<piece[0].length; i++){
		for(var j=0; j<piece.length; j++){
			if(piece[j][i] != ' '){
				result.push(j);
				break;
			}
		}
	}
	return result;
}

function dropPiece(board, piece, column){
	var width = piece[0].length;
	var height = piece.length;

	var minHeights = getColumnHeights(board);

	var pieceDepth = getPieceDepth(piece);

	var diff = pieceDepth.map(function(a,i){
		return minHeights[i+column]-a;
	});

	var rowOffset = Math.max.apply(null, diff)

	var locations = [];

	for(var i=0; i<piece.length; i++){
		for(var j=0; j<piece[i].length; j++){
			if(piece[i][j] == 'x'){
				locations.push({
					row:rowOffset+i,
					col:column+j
				});
			}
		}
	}

	return {
		locations:locations
	};
}

function getColumnHeights(board){
	var result = [];
	for(var i=0; i<board[0].length; i++){
		var height = 0;
		for(var j=board.length-1; j>=0; j--){
			if(board[j][i] !== null){
				height = j+1;
				break;
			}
		}
		result.push(height);
	}
	return result;
}

if(LOCATION.length > 0){
	joinGame('/'+LOCATION);
} else if(GAME_SIZE > 0){
	createGame(GAME_SIZE);
} else {
	console.log('invalid options provided');
}