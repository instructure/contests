#!/usr/bin/env ruby

require 'net/http'
require 'pp'
require 'json'
require 'gosu'
require 'thread'

class HexWindow < Gosu::Window
  def initialize(w, h)
    super(1024, 768, false)
    # super(Gosu.screen_width, Gosu.screen_height, true)
    self.caption = "Hex!"
    @w = w
    @h = h
    @game_w = width / w
    @game_h = height / h
    @games = Array.new(w * h)
    spawn_watcher
  end

  def watch_game(gameid)
    empty = @games.index { |g| g.nil? }
    return unless empty
    y = (empty / @w) * @game_h
    x = (empty % @w) * @game_w
    puts "watching #{gameid}"
    @games[empty] = Game.new(self, x, y, @game_w, @game_h, gameid)
  end

  def draw
    c = 0xfff3f3f3
    draw_quad(0, 0, c,
              width, 0, c,
              width, height, c,
              0, height, c)
    @games.each do |g|
      next unless g
      clip_to(g.startx, g.starty, @game_w, @game_h) do
        translate(g.startx, g.starty) do
          g.draw
        end
      end
    end
  end

  def update
    close if button_down?(Gosu::KbEscape)
    @games.each { |g| g && g.update }
  end

  def game_ended(game)
    puts "killing #{game.gameid}"
    @games[@games.index(game)] = nil
  end

  def spawn_watcher
    Thread.new do
      loop do
        res = Net::HTTP.start($host, $port) do |http|
          req = Net::HTTP::Get.new("/")
          http.request(req)
        end
        json = JSON.parse(res.body)
        json.each do |game|
          if game['state'] == 'in play' && !@games.any? { |g| g && g.gameid == game['id'] }
            watch_game(game['id'])
          end
        end
        sleep 0.5
      end
    end.abort_on_exception = true
  end
end

class Game
  attr_reader :startx, :starty, :gameid
  def initialize(window, x, y, w, h, gameid)
    @window = window
    @gameid = gameid
    @startx = x
    @starty = y
    @w = w
    @h = h
    spawn_updater
    @game = @queue.pop
    @sidebar = @w - @h
    @player_font = Gosu::Font.new(@window, 'Helvetica', 15)
    @final_font = Gosu::Font.new(@window, 'Helvetica', 30)
    @delta = [((@h - 20) / @game['cols']), ((@h - 20) / @game['rows'])].min
  end

  def g
    @window
  end

  def draw

    ### draw playfield

    c = Gosu::Color::BLACK

    # draw grid
    @game['rows'].times do |g_y|
      @game['cols'].times do |g_x|
        next if g_y.even? && g_x == @game['cols'] - 1
        x, y = g2s(g_x, g_y)
        g.draw_line(x, y, c, x+1, y+1, c)
      end
    end

    # draw lines
    @game['lines'].each_with_index do |line, i|
      line['draw'] ||= 0.0
      line['draw'] = [line['draw'] + 0.05, 1.00].min
      es = line['endpoints']
      x1, y1 = g2s(es[0]['col'], es[0]['row'])
      x2, y2 = g2s(es[1]['col'], es[1]['row'])
      x2 = x1 + (x2 - x1) * line['draw']
      y2 = y1 + (y2 - y1) * line['draw']
      if line['owner']
        c = line['owner']['name'] == @game['players'][0]['name'] ? 0xddff0000 : 0xdd0000ff
      else
        c = Gosu::Color::FUCHSIA
      end
      g.draw_line(x1, y1, c, x2, y2, c)
    end

    # draw hexagons
    @game['hexagons'].each do |hex|
      hex['vis'] ||= Gosu::Color.new(hex['owner']['name'] == @game['players'][0]['name'] ? 0x33ff0000 : 0x330000ff)
      hex['vis'].alpha = [hex['vis'].alpha + 0x05, 0xdd].min
      c = hex['vis']
      cx, cy = [hex['center']['col'], hex['center']['row']]
      scale_factor = 1.0 + (0xdd - hex['vis'].alpha) / 0xdd.to_f
      g.translate(*g2s(cx, cy)) do
        g.scale(scale_factor) do
          draw_hexagon(c)
        end
      end
    end

    ### draw sidebar

    # draw players
    @player_font.draw("gameid: #{@gameid}", 5, 5, 0, 1, 1, Gosu::Color::BLACK)
    player = @game['players'][0]
    @player_font.draw("#{player['name']}: #{player['score']}", 5, 35, 0, 1, 1, Gosu::Color::RED) if player
    player = @game['players'][1]
    @player_font.draw("#{player['name']}: #{player['score']}", 5, 65, 0, 1, 1, Gosu::Color::BLUE) if player

    # draw recent moves
    (@game['lines'].reverse[0,20]).each_with_index do |line, i|
      next unless line['owner']
      c = line['owner']['name'] == @game['players'][0]['name'] ? Gosu::Color::RED : Gosu::Color::BLUE
      @player_font.draw("(#{line['endpoints'][0]['row']},#{line['endpoints'][0]['col']}) -> (#{line['endpoints'][1]['row']},#{line['endpoints'][1]['col']})",
                        5, 110 + 30 * i, 0, 1, 1, c)
    end

    # draw the winner?
    if @winner
      width = @final_font.text_width(@winner)
      left = @w / 2 - width / 2
      top = @wpos
      g.draw_quad(left - 10, top - 10, 0xdd999999, left + 10 + width, top - 10, 0xdd999999, left + 10 + width, top + 10 + 70, 0xdd9999ff, left - 10, top + 10 + 70, 0xdd9999ff)
      @final_font.draw(@winner, left, top, 0, 1, 1, Gosu::Color::BLACK)
    end
  end

  def g2s(g_x, g_y)
    x = @sidebar + 10 + @delta / 2 + g_x * @delta
    x += @delta / 2 if g_y.even?
    y = 10 + @delta / 2 + g_y * @delta
    [x, y]
  end

  def draw_hexagon(c)
    x0, y0 = [0, 0]
    b = Gosu::Color::BLACK
    x1, y1 = [x0 - @delta / 2 - 1, y0 - @delta - 1]
    x2, y2 = [x0 + @delta / 2, y0 - @delta - 1]
    g.draw_triangle(x0, y0, c, x1, y1, c, x2, y2, c)
    g.draw_line(x1, y1, b, x2, y2, b)
    x1, y1 = [x0 + @delta, y0]
    g.draw_triangle(x0, y0, c, x1, y1, c, x2, y2, c)
    g.draw_line(x1, y1, b, x2, y2, b)
    x2, y2 = [x0 + @delta / 2, y0 + @delta]
    g.draw_triangle(x0, y0, c, x1, y1, c, x2, y2, c)
    g.draw_line(x1, y1, b, x2, y2, b)
    x1, y1 = [x0 - @delta / 2 - 1, y0 + @delta]
    g.draw_triangle(x0, y0, c, x1, y1, c, x2, y2, c)
    g.draw_line(x1, y1, b, x2, y2, b)
    x2, y2 = [x0 - @delta - 1, y0]
    g.draw_triangle(x0, y0, c, x1, y1, c, x2, y2, c)
    g.draw_line(x1, y1, b, x2, y2, b)
    x1, y1 = [x0 - @delta / 2 - 1, y0 - @delta - 1]
    g.draw_triangle(x0, y0, c, x1, y1, c, x2, y2, c)
    g.draw_line(x1, y1, b, x2, y2, b)
  end

  def update
    delta = @queue.pop unless @queue.empty?
    delta.each do |k,v|
      if k == 'players'
        v.each do |p|
          if player = @game['players'].find { |op| op['name'] == p['name'] }
            p.keys.each { |pk| player[pk] = p[pk] }
          else
            @game['players'] << p
          end
        end
      elsif %w(lines hexagons).include?(k)
        @game[k] += v
      else
        @game[k] = v
      end
    end if delta

    if !@winner && @game['state'] == 'completed'
      player = nil
      if @game['players'][0]['score'] == 'disqualified'
        player = @game['players'][1]['name']
      elsif @game['players'][1]['score'] == 'disqualified'
        player = @game['players'][0]['name']
      else
        score_sort = @game['players'].sort_by { |p| p['score'].to_i }
        if score_sort.map { |s| s['score'] }.uniq.size > 1
          player = score_sort.last['name']
        end
      end
      if player
        strs = [
          "%s dominates!",
          "winner: %s",
          "w00t %s",
          "bow down to %s",
        ]
        @winner = strs[rand(strs.size)] % player
      else
        @winner = "a tie :/"
      end
      @wpos = -100
    end
    if @wpos
      if @wpos < @h / 2 - 60
        @wpos = [@wpos + 8, @h / 2 - 60].min
      elsif !@end_timer
        @end_timer = true
        Thread.new { sleep(5); g.game_ended(self) }
      end
    end
  end

  def button_up(b)
    case b
    when Gosu::KbG
      pp @game
    end
  end

  def needs_cursor?
    true
  end

  def spawn_updater
    @queue = Queue.new
    Thread.new do
      until @game && @game['state'] == 'completed'
        http = Net::HTTP.start($host, $port)
        req = Net::HTTP::Post.new("/#{@gameid}/observers")
        http.request(req) do |res|
          @token = res['X-Observer-Token']
          cur_chunk = ""
          res.read_body do |chunk|
            cur_chunk << chunk
            while cur_chunk.index("\n")
              json_str, cur_chunk = cur_chunk.split("\n", 2)
              @queue << JSON.parse(json_str)
            end
          end
        end
      end
    end.abort_on_exception = true
  end
end

$host, $port, w, h = *ARGV
unless $host && $port
  puts "usage: #{$0} [HOST] [PORT] ([GAMEID] | [ROWS]x[COLS])"
  exit
end

http = Net::HTTP.start($host, $port)

def mkgame(rows = nil, cols = nil)
  req = Net::HTTP::Post.new("/")
  req.body = { 'rows' => (rows || 5).to_i, 'cols' => (cols || 5).to_i }.to_json
  res = Net::HTTP.start($host, $port) { |http| http.request(req) }
  raise("Couldn't start new game: #{res.inspect}") unless res.code == '201'
  gameid = res['Location'].sub(%r{^/}, '')
  puts gameid
  $w.watch_game(gameid)
end

# if gameid =~ %r{([\d]+)x([\d]+)}
#   rows = $1
#   cols = $2
#   gameid = nil
# end

# # if no gameid given, create a new gameid
# unless gameid
#   req = Net::HTTP::Post.new("/")
#   req.body = { 'rows' => (rows || 5).to_i, 'cols' => (cols || 5).to_i }.to_json
#   res = http.request(req)
#   raise("Couldn't start new game: #{res.inspect}") unless res.code == '201'
#   gameid = res['Location'].sub(%r{^/}, '')
# end
# puts "gameid: #{gameid}"

# require 'irb'
# Thread.new do
#   ARGV.clear
#   IRB.start
# end

$w = HexWindow.new((w||2).to_i,(h||2).to_i)
$w.show
