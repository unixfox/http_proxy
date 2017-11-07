require "../src/http_proxy"
require "option_parser"

host = "127.0.0.1"
port = 8080

OptionParser.parse! do |opts|
  opts.on("-h HOST", "--host HOST", "define host to run server") do |opt|
    host = opt
  end

  opts.on("-p PORT", "--port PORT", "define port to run server") do |opt|
    port = opt.to_i
  end
end

proxy_client = HTTP::Proxy::Client.new(host, port)

client = HTTP::Client.new("httpbin.org")
client.set_proxy(proxy_client)
response = client.get("https://httpbin.org/get")
puts response.body