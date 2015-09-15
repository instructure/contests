require 'pp'

class Randomer
  def get_next_move(game)
    loop do
      pt = { 'col' => rand(game['cols']), 'row' => rand(game['rows']) }
      pt2 = { 'col' => pt['col'] + 1, 'row' => pt['row'] }
      test = [pt, pt2]
      if ok_move?(game, test)
        return test
      end
      pt2 = { 'col' => pt['col'], 'row' => pt['row'] + 1 }
      test = [pt, pt2]
      if ok_move?(game, test)
        return test
      end
      pt2 = { 'col' => pt['col'] + (pt['row'] % 2 == 0 ? 1 : -1), 'row' => pt['row'] + 1 }
      test = [pt, pt2]
      if ok_move?(game, test)
        return test
      end
    end
  end

  def ok_move?(game, line)
    line[0]['col'] >= 0 && line[1]['col'] >= 0 &&
    line[0]['col'] < cols_in_row(game, line[0]['row']) &&
    line[1]['col'] < cols_in_row(game, line[1]['row']) &&
      line[1]['row'] < game['rows'] &&
      !game['lines'].map { |l| l['endpoints'] }.include?(line) &&
      !game['hexagons'].any? { |h| h['center'] == line[0] || h['center'] == line[1] }
  end

  def cols_in_row(game, row)
    game['cols'] - (row % 2 == 0 ? 1 : 0)
  end
end
