def map_character(character)
  case character
  when /[ABC]/i  then '2'
  when /[DEF]/i  then '3'
  when /[GHI]/i  then '4'
  when /[JKL]/i  then '5'
  when /[MNO]/i  then '6'
  when /[PQRS]/i then '7'
  when /[TUV]/i  then '8'
  when /[WXYZ]/i then '9'
  when /\d/      then character
  else ''
  end
end

while line = gets
  line.chomp!
  puts line.each_char.map{ |ch| map_character(ch) }.join('')
end
