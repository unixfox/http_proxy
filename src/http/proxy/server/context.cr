class HTTP::Proxy::Server < HTTP::Server
  class Context < HTTP::Server::Context
    def perform
      return if @performed

      @performed = true

      case @request.method
      when "OPTIONS"
        @response.headers["Allow"] = "OPTIONS,GET,HEAD,POST,PUT,DELETE,CONNECT"
      when "CONNECT"
        host, port = @request.resource.split(":", 2)

        upstream = TCPSocket.new(host, port)

        @response.reset
        @response.upgrade do |downstream|
          downstream = downstream.as(TCPSocket)
          downstream.sync = true

          spawn do
            spawn { IO.copy(upstream, downstream) }
            spawn { IO.copy(downstream, upstream) }
          end
        end
      else
        uri = URI.parse(@request.resource)
        if ((uri.host || "").includes?("www.google") || (uri.host || "") === "www.youtube.com")
          client = QUIC::Client.new(uri.host || "www.google.com")

          @request.headers.delete("Accept-Encoding")
          @request.headers.delete("Host")
          @request.headers.delete("Proxy-Connection")

          response = client.get(uri.full_path, headers: @request.headers)

          response.headers.delete("Transfer-Encoding")
          response.headers.delete("Content-Encoding")

          @response.headers.merge!(response.headers)
          @response.status_code = response.status_code
          @response.puts(response.body)
        else
          uri = URI.parse(@request.resource)
          client = HTTP::Client.new(uri)

          @request.headers.delete("Accept-Encoding")

          response = client.exec(@request)

          response.headers.delete("Transfer-Encoding")
          response.headers.delete("Content-Encoding")

          @response.headers.merge!(response.headers)
          @response.status_code = response.status_code
          @response.puts(response.body)
        end
      end
    end
  end
end
