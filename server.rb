require 'socket'

def handle_connection(socket)
  message = socket.gets

  puts message

  response = "Hello World!\n"

  socket.print "HTTP/1.1 200 OK\r\n" +
               "Content-Type: text/plain\r\n" +
               "Content-Length: #{response.bytesize}\r\n" +
               "Connection: close\r\n"\

  socket.print "\r\n"

  socket.print response

  socket.close
end

server = TCPServer.new('0.0.0.0', 8080)
loop do
  socket = server.accept
  Thread.new { handle_connection(socket) }
end