require 'socket'
require 'uri'
require 'cgi'
require 'byebug'
require 'erb'

def handle_connection(socket)
  message = socket.gets

  verb, address, protocol = message.split(' ')

  uri = URI.parse(address.to_s)

  cgi = CGI.parse(uri.query.to_s)

  response = 
    case address
    when '/'
      template = ERB.new(File.read('templates/index.html.erb'))
      [200, template.result]
    when '/hello_world'
      template = ERB.new(File.read('templates/hello_world.html.erb'))
      [200, template.result]
    when /^\/foobar/
      foos = Array(cgi["foos"])[0].to_s
      bars = Array(cgi["bars"])[0].to_s
      template = ERB.new(File.read('templates/foobar.html.erb'))
      [200, template.result]
    else
      template = ERB.new(File.read('templates/404.html.erb'))
      [404, template.result]
    end

  socket.print "HTTP/1.1 #{response[0]} OK\r\n" +
               "Content-Type: text/html\r\n" +
               "Content-Length: #{response[1].bytesize}\r\n" +
               "Connection: close\r\n"

  socket.print "\r\n"

  socket.print "#{response[1]}\r\n"

  socket.close
end

server = TCPServer.new('0.0.0.0', 8080)
loop do
  socket = server.accept
  Thread.new { handle_connection(socket) }
end