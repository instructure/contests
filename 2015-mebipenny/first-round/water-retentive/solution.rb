def process(line)
  heights = line.split(' ').map(&:to_i)

  result = 0

  # at each height, find the walls to the furthest
  # left and right, subtract how many walls are
  # between them
  1.upto(heights.max) do |height|
    left = heights.find_index {|h| h >= height }
    right = heights.length - heights.reverse.find_index {|h| h >= height }
    next unless right && left

    left.upto(right - 1) do |i|
      if heights[i] < height
        result += 1
      end
    end
  end

  return result
end

$stdin.each_line do |line|
  puts process(line)
end

