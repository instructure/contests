$coded = {
  'A' => '._',
  'B' => '_...',
  'C' => '_._.',
  'D' => '_..',
  'E' => '.',
  'F' => '.._.',
  'G' => '__.',
  'H' => '....',
  'I' => '..',
  'J' => '.___',
  'K' => '_._',
  'L' => '._..',
  'M' => '__',
  'N' => '_.',
  'O' => '___',
  'P' => '.__.',
  'Q' => '__._',
  'R' => '._.',
  'S' => '...',
  'T' => '_',
  'U' => '.._',
  'V' => '..._',
  'W' => '.__',
  'X' => '_.._',
  'Y' => '_.__',
  'Z' => '__..'
}

def solve(string)
  if string.empty?
    yield ""
    return
  end

  ('A'..'Z').each do |letter|
    prefix = $coded[letter]
    n = prefix.size
    if string[0...n] == prefix
      solve(string[n..-1]) do |solution|
        yield letter + solution
      end
    end
  end
end

if string = gets
  solve(string.chomp) do |solution|
    puts solution
  end
end
