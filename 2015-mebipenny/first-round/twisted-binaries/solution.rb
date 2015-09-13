needle = $stdin.readline.to_i

last_num = 0
i = 0
last_invalid = false

until $stdin.eof?
  num = $stdin.readline.to_i
  if num < last_num
    last_invalid = true
  else
    if !last_invalid && last_num == needle
      puts i-1
      exit
    elsif !last_invalid && last_num > needle
      puts -1
      puts i-1
      exit
    end
    last_invalid = false
    last_num = num
  end
  i += 1
end

if last_num == needle
  puts i-1
else
  puts -1
  puts i
end
