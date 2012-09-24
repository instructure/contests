number = gets.chomp
if !number || number.to_i < 1 || number.to_i > 9999
  puts "Must provide a number 1 to 9999"
  exit
end

#             0 1 2  3   4  5 6  7   8    9
HUNDREDS = %w[_ C CC CCC CD D DC DCC DCCC CM]
TENS     = %w[_ X XX XXX XL L LX LXX LXXX XC]
ONES     = %w[_ I II III IV V VI VII VIII IX]

def digit_to_numeral(digit, place)
  digit = digit.to_i
  return if digit == 0
  case place
  when 4
    'M' * digit
  when 3
    HUNDREDS[digit]
  when 2
    TENS[digit]
  when 1
    ONES[digit]
  end
end

numeral = []
place = number.size

number.each_char do |char|
  numeral << digit_to_numeral(char, place)
  place = place - 1
end

puts numeral.join
