balance = $stdin.readline.to_i
coins = 0

$stdin.each_line do |line|
  price, action = line.split
  price = price.to_i
  case action
  when 'buy'
    balance -= price
    coins += 1
  when 'sell'
    balance += price
    coins -= 1
  end
  # just here to check my test cases
  raise "#{line} invalid" if balance < 0
  raise "#{line} coins" if coins < 0
end

puts balance
