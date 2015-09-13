rows, cols = $stdin.readline.split.map(&:to_i)

basket = Hash.new(0)

rows.times do |y|
  nums = $stdin.readline.split.map(&:to_i)
  nums.each_with_index { |n,x| basket[[x,y]] = n }
end

days = 0

loop do
  if basket.all? { |k,n| n == 0 || n == 2 }
    puts days
    break
  end

  new_state = basket.dup

  rows.times do |y|
    cols.times do |x|
      next unless new_state[[x,y]] == 1
      if basket[[x-1,y]] == 2 || basket[[x+1,y]] == 2 || basket[[x,y-1]] == 2 || basket[[x,y+1]] == 2
        new_state[[x,y]] = 2
      end
    end
  end

  if new_state == basket
    puts -1
    break
  end

  days += 1

  basket = new_state
end
