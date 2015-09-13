board = []
loop do
  break unless (line = STDIN.gets)
  line = line.chomp
  break if line.empty?

  board << line.split(" ")
end
n = board.length

def neighbors(r,c,n)
  ns = []
  ns << [r-1, c] if r-1 > 0
  ns << [r+1, c] if r+1 < n
  ns << [r, c-1] if c-1 > 0
  ns << [r, c+1] if c+1 < n
  ns
end

def connected(p, board, visited, n)
  queue = [p]
  component = []
  while !queue.empty?
    check = queue.pop
    if board[check[0]][check[1]] == "_" && !visited.include?(check)
      visited << check
      component << check
      queue += (neighbors(check[0], check[1], n) - visited)
    else
      visited << check
    end
  end
  component
end

visited = []
components = []
n.times do |r|
  n.times do |c|
    if board[r][c] == "_" && !visited.include?([r,c])
      components << connected([r,c], board, visited, n)
    end
  end
end

black = 0
white = 0
components.each do |comp|
  border = comp.map{|c| neighbors(c[0], c[1], n)}.flatten(1) - comp
  bcolor = border.map{|c| board[c[0]][c[1]]}
  black += comp.size if bcolor.all?{|c| c == "B"}
  white += comp.size if bcolor.all?{|c| c == "W"}
end

puts "Black: #{black}"
puts "White: #{white}"
