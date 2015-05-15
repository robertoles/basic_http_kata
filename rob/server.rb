require 'socket'
require 'uri'
require 'cgi'
require 'byebug'
require 'erb'

class Route
  attr_reader :name, :path

  def initialize(name, options={})
    @name = name
    @path = options[:path] || "/#{name}"
  end

  def for_path?(path)
    path.match(/^#{@path}/)
  end

  def code
    200
  end 
end

class RouteNotFound
  def for_path?(path)
    true
  end

  def code
    404
  end

  def name
    "404"
  end

  def path
    "unfound"
  end
end

class Params

  attr_reader :cgi

  def initialize(query)
    @cgi = CGI.parse(query.to_s)
  end

  def method_missing(name)
    return nil unless cgi[name.to_s]
    cgi[name.to_s][0]
  end

end

def handle_connection(socket)
  message = socket.gets

  verb, path, protocol = message.split(' ')

  uri = URI.parse(path.to_s)
  params = Params.new(uri.query)

  routes = [
    Route.new('hello_world'),
    Route.new('foobar'),
    Route.new('index', path: '/'),
    RouteNotFound.new
  ]

  route = routes.find { |route| route.for_path?(path) }
  
  response = ERB.new(File.read("templates/#{route.name}.html.erb")).result(binding)

  socket.print "HTTP/1.1 #{route.code} OK\r\n" +
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

