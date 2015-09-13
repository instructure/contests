def process(line)
    line.gsub(%r{([A-Z])\1*}) { |str| str.length < 2 ? str : "#{str[0]}#{str.length}" }
end

$stdin.each_line do |line|
    puts process(line)
end
