#!/usr/bin/ruby

n, m, k = gets.split.map(&:to_i)
mines = {}
cells = {}
k.times do
  x, y = gets.split.map(&:to_i)
  mines[x] ||= {}
  mines[x][y] = true
  [-1, 0, 1].each do |dx|
    [-1, 0, 1].each do |dy|
      cells[x + dx] ||= {}
      cells[x + dx][y + dy] = true
    end
  end
end

cells.keys.sort.each do |x|
  next if x < 0 || x >= n
  cells[x].keys.sort.each do |y|
    next if y < 0 || y >= m
    next if mines.has_key?(x) && mines[x].has_key?(y)
    count = 0
    [-1, 0, 1].each do |dx|
      next unless mines.has_key?(x+dx)
      [-1, 0, 1].each do |dy|
        count += 1 if mines[x + dx].has_key?(y + dy)
      end
    end
    puts "#{x} #{y} #{count}"
  end
end
