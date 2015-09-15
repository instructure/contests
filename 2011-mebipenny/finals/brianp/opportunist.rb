require 'set'
require 'pp'

class Opportunist
  def initialize
    @illegal = Set.new
  end

  def get_next_move(game)
    legal_moves = Set.new
    0.upto(game['rows']) do |y|
      0.upto(game['cols']) do |x|
        pt1 = { 'col' => x, 'row' => y }
        possibles = [
          [pt1, { 'col' => x + 1, 'row' => y }],
          [pt1, { 'col' => x, 'row' => y + 1 }],
          [pt1, { 'col' => x + (y % 2 == 0 ? 1 : -1), 'row' => y + 1}],
        ]
        possibles.reject! { |p| !ok_move?(game, p) }
        legal_moves.merge(possibles)
      end
    end
    # find moves that'll complete a hex
    awesome_moves = legal_moves.find_all do |line|
      line_completes_hex?(game, line)
    end

    if awesome_moves.empty?
      return legal_moves.to_a[rand(legal_moves.size)]
    else
      puts "found awesome move"
      return awesome_moves.to_a[rand(awesome_moves.size)]
    end
  end

  def ok_move?(game, line)
    return false if @illegal.include?(line)
    ok = line[0]['col'] >= 0 && line[1]['col'] >= 0 &&
    line[0]['col'] < cols_in_row(game, line[0]['row']) &&
    line[1]['col'] < cols_in_row(game, line[1]['row']) &&
      line[1]['row'] < game['rows'] &&
      !game['lines'].map { |l| l['endpoints'] }.include?(line) &&
      !game['hexagons'].any? { |h| h['center'] == line[0] || h['center'] == line[1] }
    @illegal << line unless ok
    ok
  end

  def neighborhood(game, pt)
    x, y = [pt['col'], pt['row']]
    [
     { 'row' => y - 1, 'col' => x - (y % 2 == 0 ? 0 : 1) },
     { 'row' => y - 1, 'col' => x + (y % 2 == 1 ? 0 : 1) },
     { 'row' => y, 'col' => x + 1},
     { 'row' => y + 1, 'col' => x + (y % 2 == 0 ? 1 : 0) },
     { 'row' => y + 1, 'col' => x - (y % 2 == 1 ? 1 : 0) },
     { 'row' => y, 'col' => x - 1},
    ].reject { |p| p['row'] < 0 || p['col'] < 0 || p['row'] >= game['rows'] || p['col'] >= cols_in_row(game, p['row']) }
  end

  def line_completes_hex?(game, line)
    candidates = neighborhood(game, line[0]) & neighborhood(game, line[1])
    hexes = candidates.select { |c| hex_complete?(game, c, line) }
    hexes.size > 0
  end

  def hex_complete?(game, pt, new_line)
    pts = neighborhood(game, pt)
    pts.size == 6 && (0..5).all? do |i|
      nl = [pts[i], pts[(i+1) % 6]].sort_by { |v| [v['row'], v['col']] }
      res = !line_in_hex?(game, new_line) && (game['lines'].any? { |l| l['endpoints'] == nl } || new_line == nl)
      res
    end
  end

  def line_in_hex?(game, line)
    !(line & game['hexagons'].map { |h| h['center'] }).empty?
  end

  def cols_in_row(game, row)
    game['cols'] - (row % 2 == 0 ? 1 : 0)
  end
end
