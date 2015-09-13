nlines = $stdin.readline.to_i

class Point < Struct.new(:x, :y, :visited)
end

locations = nlines.times.map { Point.new(*$stdin.readline.split(",").map(&:to_f)) }
position = Point.new(0.5,0.5)
travel = 0.0

class Node < Struct.new(:point, :left, :right)
end

def distance(p1, p2)
  Math.sqrt((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2)
end

def build_tree(points, depth = 0)
  return nil if points.empty?
  axis = depth % 2 == 0 ? :x : :y
  points = points.sort_by(&axis)
  median = points.size / 2

  Node.new(
    points[median],
    build_tree(points[0,median], depth+1),
    build_tree(points[median+1,points.length], depth+1)
  )
end

def valid_node?(node)
  node && !node.point.visited
end

def find_nearest(node, pos, depth = 0)
  axis = depth % 2 == 0 ? :x : :y
  return nil if !node

  if node.point.send(axis) > pos.send(axis)
    move = :left
    other = :right
  else
    move = :right
    other = :left
  end

  new_node = node.send(move)
  best = find_nearest(new_node, pos, depth+1)

  # If the current node is closer than the current best, then it becomes the current best.
  if valid_node?(node) && (!best || (distance(pos, best.point) > distance(pos, node.point)))
    best = node
  end

  # if the difference between the splitting coordinate of the search point and current node
  diff = (pos.send(axis) - node.point.send(axis)).abs
  # lesser than the distance (overall coordinates) from the search point to the current best
  if !best || diff < distance(pos, best.point)
    other_node = node.send(other)
    best2 = find_nearest(other_node, pos, depth+1)
    if valid_node?(best2) && (!best || distance(pos, best2.point) < distance(pos, best.point))
      best = best2
    end
  end

  best
end

tree = build_tree(locations)

locations.size.times do
  point = find_nearest(tree, position).point
  point.visited = true
  travel += distance(position, point)
  position = point
end

puts("%.2f" % [travel])

