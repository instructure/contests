def product(*sets)
  raise ArgumentError if sets.empty?
  return sets.first.map{ |el| [el] } if sets.size == 1
  sub_product = product *sets[1..-1]
  sets.first.map do |el|
    sub_product.map do |list|
      [el, *list]
    end
  end.flatten(1)
end

clothing = []
while line = gets
  clothing << line.split
end

outfits = product *clothing

outfits.each do |outfit|
  puts outfit.join(' ')
end
