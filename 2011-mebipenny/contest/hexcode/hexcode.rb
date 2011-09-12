
def is_valid_one_char(char)
  char = char.hex
  return char >= 1 && char <= 26
end

def is_valid_two_char(chars)
  char = chars.hex
  return char >= 1 && char <= 26 && chars[0..0] != "0"
end

def count_interpretations(xs, a, b)
  return 0 if a == 0 and b == 0
  return a if xs.size == 0
  if xs.size == 1
    return a + b if is_valid_one_char(xs[0..0])
    return b
  end
  return count_interpretations(xs[1..-1],
      is_valid_one_char(xs[0..0]) ? a + b : b,
      is_valid_two_char(xs[0..1]) ? a : 0)
end

loop do
  line = gets.strip
  break if line == "0"
  puts count_interpretations(line, 1, 0)
end
