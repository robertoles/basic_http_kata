require 'socket'

def handle_connection(socket)
  message = socket.gets

  verb, address, protocol = message.split(' ')

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