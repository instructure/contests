# taken from http://rosettacode.org/wiki/Closest-pair_problem
# with modifications

Point = Struct.new(:x, :y)
c, g = gets.split.map(&:to_i)
ids = {}
$is_chicken = {}
points = []
(c+g).times do |i|
  id, x, y = gets.split.map(&:to_i)
  ids[x] ||= {}
  ids[x][y] = id
  $is_chicken[x] ||= {}
  $is_chicken[x][y] = (i < c)
  points << Point.new(x, y)
end

def is_differing_type(point1, point2)
  $is_chicken[point1.x][point1.y] != $is_chicken[point2.x][point2.y]
end

def distance(p1, p2)
  Math.hypot(p1.x - p2.x, p1.y - p2.y)
end

def closest_bruteforce(points)
  mindist, minpts = Float::MAX, []
  points.length.times do |i|
    (i+1).upto(points.length - 1) do |j|
      dist = distance(points[i], points[j])
      if dist < mindist and is_differing_type(points[i], points[j])
        mindist = dist
        minpts = [points[i], points[j]]
      end
    end
  end
  [mindist, minpts]
end

def closest_recursive(points)
  if points.length <= 3
    return closest_bruteforce(points)
  end
  xP = points.sort_by {|p| p.x}
  mid = (points.length / 2.0).ceil
  pL = xP[0,mid]
  pR = xP[mid..-1]
  dL, pairL = closest_recursive(pL)
  dR, pairR = closest_recursive(pR)
  if dL < dR
    dmin, dpair = dL, pairL
  else
    dmin, dpair = dR, pairR
  end
  yP = xP.find_all {|p| (pL[-1].x - p.x).abs < dmin}.sort_by {|p| p.y}
  closest = Float::MAX
  closestPair = []
  0.upto(yP.length - 2) do |i|
    (i+1).upto(yP.length - 1) do |k|
      break if (yP[k].y - yP[i].y) >= dmin
      dist = distance(yP[i], yP[k])
      if dist < closest and is_differing_type(yP[i], yP[k])
        closest = dist
        closestPair = [yP[i], yP[k]]
      end
    end
  end
  if closest < dmin
    [closest, closestPair]
  else
    [dmin, dpair]
  end
end

distance, pair = closest_recursive(points)
if $is_chicken[pair[0].x][pair[0].y]
  puts "#{ids[pair[0].x][pair[0].y]} #{ids[pair[1].x][pair[1].y]}"
else
  puts "#{ids[pair[1].x][pair[1].y]} #{ids[pair[0].x][pair[0].y]}"
end
