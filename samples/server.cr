require "../src/http_proxy"

host = "::"
port = 8080

server = HTTP::Proxy::Server.new(host, port, handlers: [
  HTTP::LogHandler.new,
])

server.bind_tcp(host, port)

puts "Listening on http://#{server.host}:#{server.port}"
server.listen
