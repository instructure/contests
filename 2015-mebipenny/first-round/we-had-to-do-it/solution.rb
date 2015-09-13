x = $stdin.readline.to_i
y = $stdin.readline.to_i
z = $stdin.readline.to_i

1.upto(x) do |i|
  puts(case
  when i % y == 0 && i % z == 0
    "FizzBuzz"
  when i % y == 0
    "Fizz"
  when i % z == 0
    "Buzz"
  else
    i
  end)
end
