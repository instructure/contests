KEEP_RESULT = false

def formatter(significant, next_code)
  # format with the right number of hex digits for our size
  result = format("%0#{significant}x", next_code)
  [result, next_code + 1]
end

def compress(line, size)
  # initialize
  dictionary = {}
  sequence = ""
  result = ""
  length = 0
  next_code = 0

  significant = size / 4
  %w(A G C T).map do |dna|
    dictionary[dna], next_code = formatter(significant, next_code)
  end

  # for each character
  line.each_char do |char|
    next_sequence = "#{sequence}#{char}"
    # if the sequence with the new char is in the dict, continue
    if dictionary.has_key?(next_sequence)
      sequence = next_sequence
    # otherwise
    else
      # make a new code, if possible
      if next_code < (2 ** size)
        dictionary[next_sequence], next_code = formatter(significant, next_code)
      end
      # add the code to the result
      result += dictionary[sequence] if KEEP_RESULT
      length += dictionary[sequence].length
      # and continue with the new char
      sequence = char
    end
  end
  # finish up any loose ends
  result += dictionary[sequence] if KEEP_RESULT
  length += dictionary[sequence].length
  length
end

while line = gets
  line = line.strip

  options = [
    # length of 2 bit encoding is just length of string * 2
    [line.length * 2, "2"],

    # all the rest we are keeping track of in hex, so multiply by 4 for bits
    [compress(line, 4) * 4, "4"],
    [compress(line, 8) * 4, "8"],
    [compress(line, 16) * 4, "16"],
    [compress(line, 32) * 4, "32"],
  ]

  puts options.sort_by{|opt| opt.first}.first[1]
end
