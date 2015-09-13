board = $stdin.readlines.map { |line| line.chomp.split(",") }

def find_wins(board, x, y)
  return [] if board[y][x] == '_'
  wins = []

  if x <= board.first.size - 4
    if board[y][x,4].all? { |v| v == board[y][x] }
      $stderr.puts "x"
      wins << [x,y]
    end
  end
  
  if y <= board.size - 4
    if board[y][x] == board[y+1][x] && board[y][x] == board[y+2][x] && board[y][x] == board[y+3][x]
      $stderr.puts "y"
      wins << [x,y]
    end
  end
  
  if x <= board.first.size - 4 && y <= board.size - 4
    if board[y][x] == board[y+1][x+1] && board[y][x] == board[y+2][x+2] && board[y][x] == board[y+3][x+3]
      $stderr.puts "xy"
      wins << [x,y]
    end
  end

  if x >= 3 && y <= board.size - 4
    if board[y][x] == board[y+1][x-1] && board[y][x] == board[y+2][x-2] && board[y][x] == board[y+3][x-3]
      $stderr.puts "yx"
      wins << [x,y]
    end
  end
  
  wins
end

def score(board)
  rows = board.size
  cols = board.first.size
  wins = []
  0.upto(rows-1) do |y|
    0.upto(cols-1) do |x|
      wins += find_wins(board, x, y)
    end
  end
  wins
end

wins = score(board)
case wins.size
when 0
  r_board = board.map { |l| l.map { |v| v == '_' ? 'R' : v } }
  b_board = board.map { |l| l.map { |v| v == '_' ? 'B' : v } }
  if score(r_board).size > 0 || score(b_board).size > 0
    puts "Unsettled"
  else
    puts "Draw"
  end
  puts board.map { |l| l.select { |v| v == '_' }.size }.inject(:+)
when 1
  win = wins.first
  puts "Win_#{board[win[1]][win[0]]}"
  puts "[#{win[1]},#{win[0]}]"
else
  puts "Invalid"
  wins.each { |win|
    puts "[#{win[1]},#{win[0]}]"
  }
end
