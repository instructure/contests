
require 'set'

class Graph
  def initialize
    @edges = Hash.new{|hash, key| hash[key] = [].to_set}
    @capacities = Hash.new{|hash, key| hash[key] = 0}
  end

  def addEdge(v1, v2, c)
    @edges[v1].add v2
    @edges[v2].add v1
    @capacities[[v1, v2]] = c
  end

  def findPath(s, t, flow)
    parent = Hash.new{|h,k| h[k] = -1}
    parent[s] = -2
    bottleneck = Hash.new{|h,k| h[k] = Float::MAX}
    queue = []
    queue << s
    while queue.size > 0
      u = queue.pop
      @edges[u].each do |v|
        current_capacity = @capacities[[u,v]] - flow[[u,v]]
        next if current_capacity <= 0
        next if parent[v] != -1
        parent[v] = u
        bottleneck[v] = [bottleneck[u], current_capacity].min
        if v != t
          queue << v
        else
          path = [t]
          while path[0] != s
            path = [parent[path[0]]] + path
          end
          return path, bottleneck[t]
        end
      end
    end
    return nil, nil
  end

  def maxFlow(s, t)
    flow = Hash.new{|h,k| h[k] = 0}
    loop do
      path, bottleneck = findPath(s, t, flow)
      break if path == nil
      raise if bottleneck >= Float::MAX
      i = 1
      while i < path.size
        flow[[path[i-1], path[i]]] += bottleneck
        flow[[path[i], path[i-1]]] -= bottleneck
        i += 1
      end
    end
    sum = 0
    @edges[s].each do |v|
      sum += flow[[s,v]]
    end
    return sum
  end

end

cave_count = gets.strip.to_i
corridor_count = gets.strip.to_i
g = Graph.new
corridor_count.times do
  a, b, c = gets.strip.split.map(&:to_i)
  g.addEdge(a, b, c)
end
puts g.maxFlow(1, cave_count)
