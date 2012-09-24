
Image = Struct.new(:width, :height, :text)

def rotate(image)
  tmp = Image.new
  tmp.width = image.height
  tmp.height = image.width
  tmp.text = []
  for x in 0...image.width
    y = image.height - 1
    line = ''
    while y >= 0
      line << (image.text[y][x] || ' ')
      y -= 1
    end
    tmp.text << line
  end
  tmp
end

img = Image.new
input = ARGF.to_a
rot_iter = (input.shift.to_i / 90) % 4
img.text = input.map(&:chomp)
img.height = input.size
img.width = (img.text.max_by{|r| r.length} || '').length

rot_iter.times { img = rotate(img) }

img.text.each { |row| puts row }
