#Edge cases we'll want to include:
#1. list with no odd numbers ... perhaps we accept both 0 and ''?
#2. max is negative
#3. a really long sequence that will cause O(n**2) (or worse) to time out

while line = gets
  numbers = line.strip.split.map(&:to_i)
  cur = max = nil
  numbers.each do |i|
    if i % 2 == 0
      cur = nil
      next
    end
    cur = cur && cur > 0 ? cur + i : i
    max = max.nil? || cur > max ? cur : max
  end
  puts max || 0
end
