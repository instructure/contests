rows, cols = *ARGV

require 'net/http'
require 'json'
http = Net::HTTP.start('localhost', 9292)
req = Net::HTTP::Post.new("/")
req.body = { 'rows' => (rows || 9).to_i, 'cols' => (cols || 9).to_i }.to_json
res = http.request(req)
raise("Couldn't start new game: #{res.inspect}") unless res.code == '201'
gameid = res['Location'].sub(%r{^/}, '')
puts gameid
