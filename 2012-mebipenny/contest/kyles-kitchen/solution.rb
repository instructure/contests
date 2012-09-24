#!/usr/bin/env ruby

$shapes = {
  "A" => [ [[0, 0], [1, 0], [2, 0], [3, 0]],
           [[0, 0], [0, 1], [0, 2], [0, 3]] ],
  "B" => [ [[0, 0], [0, 1], [0, 2], [1, 2]],
           [[0, 0], [0, 1], [0, 2], [-1, 2]],
           [[0, 0], [1, 0], [2, 0], [2, 1]],
           [[0, 0], [0, -1], [1, -1], [2, -1]],
           [[0, 0], [-1, 0], [-1, 1], [-1, 2]],
           [[0, 0], [1, 0], [1, 1], [1, 2]],
           [[0, 0], [0, 1], [-1, 1], [-2, 1]],
           [[0, 0], [0, 1], [1, 1], [2, 1]] ],
  "C" => [ [[0, 0], [1, 0], [1, 1], [0, 1]] ],
  "D" => [ [[0, 0], [0, 1], [1, 1], [1, 2]],
           [[0, 0], [0, 1], [-1, 1], [-1, 2]],
           [[0, 0], [1, 0], [1, -1], [2, -1]],
           [[0, 0], [1, 0], [1, 1], [2, 1]] ],
  "E" => [ [[0, 0], [0, 1], [1, 1], [0, 2]],
           [[0, 0], [0, 1], [-1, 1], [0, 2]],
           [[0, 0], [1, 0], [1, 1], [2, 0]],
           [[0, 0], [1, 0], [1, -1], [2, 0]] ]
}

$explored_spaces = {}
$fit_all = false
def count_max_placements(remaining_tiles)
  current_grid = $grid.map(&:join).join("\n")
  return 0 if $explored_spaces[current_grid]
  $explored_spaces[current_grid] = true
  return 0 if $fit_all
  $fit_all = remaining_tiles.size == 0

  seen_tiles = {}
  max_count = 0
  remaining_tiles.each_with_index do |tile, i|
    next if seen_tiles[tile]
    next if $fit_all
    seen_tiles[tile] = true

    leftover_tiles = Array.new(remaining_tiles)
    leftover_tiles.delete_at(i)

    $n.times do |x|
      $m.times do |y|
        $shapes[tile].each do |tile_layout|
          next if $fit_all
          safe = true
          tile_layout.each do |i, j|
            if i + x >= $n or i + x < 0 or j + y >= $m or j + y < 0 or \
                $grid[i + x][j + y] != ' '
              safe = false
              break
            end
          end
          next unless safe
          tile_layout.each do |i, j|
            $grid[i + x][j + y] = tile
          end
          new_count = 1 + count_max_placements(leftover_tiles)
          max_count = new_count if new_count > max_count
          tile_layout.each do |i, j|
            $grid[i + x][j + y] = ' '
          end
        end
      end
    end
  end
  return max_count
end

def count_all_placements(tiles)
  return tiles.size if [($n / 2) * ($m / 4), ($n / 2) * ($m / 4)].max > tiles.size
  $grid = []
  $n.times { $grid << ([' '] * $m) }
  count_max_placements(tiles)
end

$n, $m = gets.split.map(&:to_i)
puts count_all_placements(gets.split)
