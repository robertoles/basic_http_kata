require 'socket'
require 'uri'
require 'cgi'
require 'byebug'

def handle_connection(socket)
  message = socket.gets

  verb, address, protocol = message.split(' ')

  uri = URI.parse(address.to_s)

  cgi = CGI.parse(uri.query.to_s)

  puts cgi.to_s

  response = 
    case address
    when '/'
      <<-RESPONSE  
        <h1>Available Routes:</h1>
        <ul>
          <li>/</li>
          <li>/hello_world</li>
          <li>/foobar</li>
        </ul>
      RESPONSE
    when '/hello_world'
      "<h1>Hello world</h1>"
    when /^\/foobar/
      foos = Array(cgi["foos"])[0].to_s
      bars = Array(cgi["bars"])[0].to_s
      result = "<div>Foos: #{foos}</div>"
      result << "<div>Bars: #{bars}</div>"
    end

  socket.print "HTTP/1.1 200 OK\r\n" +
               "Content-Type: text/html\r\n" +
               "Content-Length: #{response.bytesize}\r\n" +
               "Connection: close\r\n"

  socket.print "\r\n"

  socket.print "#{response}\r\n"

  socket.close
end

server = TCPServer.new('0.0.0.0', 8080)
loop do
  socket = server.accept
  Thread.new { handle_connection(socket) }
end