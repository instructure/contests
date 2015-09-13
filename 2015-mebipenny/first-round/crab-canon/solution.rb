def read_staff
  staff = []
  while !$stdin.eof?
    line = $stdin.readline.chomp
    break if line.empty?
    staff << line
  end
  staff
end

def reverse_staff staff
  len = staff.first.length
  staff.each_with_index.map do |line,lineno|
    sep = (lineno % 2 == 0) ? ' ' : '-'
    new_line = sep * len
    line.each_char.each_with_index do |char,i|
      val = char.to_i
      if val > 0
        new_line[len - i - val] = char
      end
    end
    new_line
  end
end

until $stdin.eof?
  staff1 = read_staff
  staff2 = read_staff
  if reverse_staff(staff2) == staff1
    puts "yes"
  else
    puts "no"
  end
end
