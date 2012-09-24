import sys

def hasMine(board, x, y):
	if (y < 0 or y >= len(board) or x < 0 or x >= len(board[0])):
		return False

	return board[y][x] == 1


def expandPoint(board, x, y, expanded = set(), points = []):
	if (y < 0 or y >= len(board) or x < 0 or x >= len(board[0])):
		return []

	if (x, y) in expanded:
		return []

	expanded.add((x, y))

	# Check this point
	if board[y][x] == 1:
		return [(x, y)]

	# Check for neighboring points
	if (hasMine(board, x-1, y-1) or
	    hasMine(board, x, y-1) or
	    hasMine(board, x+1, y-1) or
	    hasMine(board, x-1, y) or
	    hasMine(board, x+1, y) or
	    hasMine(board, x-1, y+1) or
	    hasMine(board, x, y+1) or
	    hasMine(board, x+1, y+1)):

		return [(x, y)];

	points = [(x, y)]

	points.extend(expandPoint(board, x, y-1, expanded))
	points.extend(expandPoint(board, x, y+1, expanded ))
	points.extend(expandPoint(board, x-1, y, expanded ))
	points.extend(expandPoint(board, x+1, y, expanded ))
	points.extend(expandPoint(board, x+1, y+1, expanded ))
	points.extend(expandPoint(board, x+1, y-1, expanded ))
	points.extend(expandPoint(board, x-1, y+1, expanded ))
	points.extend(expandPoint(board, x-1, y-1, expanded ))

	return points





if __name__ == "__main__":
	n, m, k = sys.stdin.readline().split(' ')
	n = int(n)
	m = int(m)
	k = int(k)

	board = [ [0 for i in range(n)] for i in range(m)]

	for i in range(k):
		x, y = sys.stdin.readline().split(' ')
		x = int(x)
		y = int(y)
		board[y][x] = 1

	x, y = sys.stdin.readline().split(' ')
	x = int(x)
	y = int(y)

	points = sorted(expandPoint(board, x, y))
	for x in points:
		print x[0], x[1]