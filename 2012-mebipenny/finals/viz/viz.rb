#!/usr/bin/env ruby

require 'net/http'
require 'pp'
require 'json'
require 'gosu'
require 'thread'

class TerritoryWindow < Gosu::Window
  def initialize(w, h)
    super(1424, 768, false)
    # super(Gosu.screen_width, Gosu.screen_height, true)
    self.caption = "Territories"
    @w = w
    @h = h
    @game_w = width / w
    @game_h = height / h
    @games = Array.new(w * h)
    spawn_watcher
  end

  def winner
    @winner ||= Gosu::Image.new(self, File.dirname(__FILE__)+"/winner.png", false, 0, 0, 182, 397)
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
    c = 0xffeeeeee
    draw_quad(0, 0, c,
              width, 0, c,
              width, height, c,
              0, height, c)
    c = 0xffcccccc
    (1..@w).each { |i| draw_line(@game_w * i, 0, c, @game_w * i, self.height, c) }
    (1..@h).each { |i| draw_line(0, @game_h * i, c, self.width, @game_h * i, c) }
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
        sleep 0.2
      end
    end.abort_on_exception = true
  end
end

class Game < Struct.new(:window, :startx, :starty, :gameid, :pw, :ph, :playfield, :players, :draw_size, :state)
  class Player < Struct.new(:player_id, :name, :score, :hand, :color)
    def initialize(id, color)
      super(id)
      self.color = color
    end
  end

  class Playfield < Struct.new(:rows, :cols)
    def initialize(rows, cols)
      super
      @tiles = []
      rows.times { |r| cols.times { |c| @tiles[c + r * cols] = Tile.new(r, c) } }
    end

    def [](row, col)
      @tiles[col + row * cols]
    end

    def each
      @tiles.each { |x| yield x }
    end
  end

  class Tile < Struct.new(:row, :col, :owner, :color)
    WALL_COLOR = Gosu::Color.new(0xccaaaaaa)
    def claimed_by(player)
      was_unclaimed = !self.owner
      if player
        self.owner = player
        self.color = player.color.dup
      else
        self.owner = :wall
        self.color = WALL_COLOR.dup
      end
      if was_unclaimed
        self.color.alpha = 0
      end
    end
  end

  def initialize(window, x, y, w, h, gameid)
    super(window, x, y, gameid, w, h)
    self.players = []
    @available_colors = PLAYER_COLORS.sort_by { rand }
    @queue = Queue.new

    spawn_updater
    game = @queue.pop

    apply_delta(game)

    @sidebar = pw - ph
    @player_font = Gosu::Font.new(window, 'Helvetica', 15)
    @final_font = Gosu::Font.new(window, 'Helvetica', 30)
    @delta = [((ph - 20) / playfield.cols), ((ph - 20) / playfield.rows)].min
  end

  alias_method :g, :window

  def available_color
    @available_colors.pop
  end

  PLAYER_COLORS = [
    Gosu::Color.new(0xffbb0000),
    Gosu::Color.new(0xff0000bb),
    Gosu::Color.new(0xff00bb00), # greenish
    Gosu::Color::FUCHSIA,
  ]

  def draw

    ### draw playfield
    c = Gosu::Color::BLACK

    # draw grid
    playfield.each do |tile|
      x, y = g2s(tile.col, tile.row)
      x2, y2 = g2s(tile.col+1, tile.row+1)
      g.draw_line(x, y, c, x2, y, c)
      g.draw_line(x2, y, c, x2, y2, c)
      g.draw_line(x, y2, c, x2, y2, c)
      g.draw_line(x, y, c, x, y2, c)

      if tile.color
        tc = tile.color
        tc.alpha = [tc.alpha + 0x05, 0xdd].min
        scale_factor = 1.0 + (0xdd - tc.alpha) / 0xdd.to_f
        g.translate(*g2s(tile.col + 0.5, tile.row + 0.5)) do
          g.scale(scale_factor) do
            sz = @delta / 2
            g.draw_quad(-sz, -sz, tc,
                        sz+1, -sz, tc,
                        sz+1, sz+1, tc,
                        -sz, sz+1, tc)
          end
        end
      end
    end

    ### draw sidebar

    # draw players
    @player_font.draw("#{gameid}", 5, 5, 0, 1, 1, Gosu::Color::BLACK)
    players.each_with_index do |player, i|
      @player_font.draw("#{player.name}: #{player.score}", 5, 35 + (30 * i), 0, 1, 1, player.color)
    end

    # draw the winner?
    if @winner
      width = @final_font.text_width(@winner)
      ctrx = pw / 2
      ctry = ph / 2
      fctr = (35 - @wrot)
      g.winner.draw_rot(ctrx, ctry, 0, @wrot, 0.5, 0.5, fctr, fctr)
      tw = @final_font.text_width(@winner)
      tbx = ctrx - (tw/2) - 10
      tbw = tbx + tw + 20
      tby = ctry - (@final_font.height / 2) - 6
      tbh = tby + @final_font.height + 12
      white = Gosu::Color::WHITE
      g.draw_quad(tbx, tby, white, tbw, tby, white, tbw, tbh, white, tbx, tbh, white)
      @final_font.draw_rel(@winner, ctrx, ctry, 3, 0.5, 0.5, 1, 1, Gosu::Color::BLACK)
    end
  end

  def g2s(g_x, g_y)
    x = @sidebar + 10 + g_x * @delta
    y = 10 + g_y * @delta
    [x, y]
  end

  def update
    delta = @queue.pop unless @queue.empty?
    apply_delta(delta) if delta

    if !@winner && state == 'completed'
      player = nil
      score_sort = players.sort_by { |p| [p['score'] == 'disqualified' ? 0 : 1, p['score'].to_i] }
      max = score_sort[-1]
      if max && score_sort[-2] != max
        player = max['name']
      end
      if player
        @winner = "a winner is #{player}"
      else
        @winner = "a winner is nobody :'("
      end
      @wrot = 0
    end
    if @wrot
      if @wrot < 34
        @wrot = [@wrot + 0.5, 34].min
      elsif !@end_timer
        @end_timer = true
        Thread.new { sleep(5); g.game_ended(self) }
      end
    end
  end

  def apply_delta(delta)
    self.draw_size = delta['draw_size']
    self.state = delta['state']

    if delta['rows'] && delta['cols']
      self.playfield = Playfield.new(delta['rows'], delta['cols'])
    end

    delta['players'].each do |json|
      player = self.players.find { |p| p.player_id == json['id'] }
      unless player
        player ||= Player.new(json['id'], available_color)
        self.players << player
      end
      %w(name score hand).each { |i| player.send("#{i}=", json[i]) }
    end

    delta['claims'].each do |claim|
      playfield[claim['tile']['row'], claim['tile']['col']].claimed_by(self.players.find { |p| p.player_id == claim['owner'] })
    end
  end

  def button_up(b)
    case b
    when Gosu::KbG
      pp self
    end
  end

  def needs_cursor?
    true
  end

  def spawn_updater
    Thread.new do
      until self.state == 'completed'
        http = Net::HTTP.start($host, $port)
        req = Net::HTTP::Post.new("/#{gameid}/observers")
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
  puts "usage: #{$0} [HOST] [PORT] ([ROWS] [COLS])"
  exit
end

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

$w = TerritoryWindow.new((w||2).to_i,(h||2).to_i)
$w.show
