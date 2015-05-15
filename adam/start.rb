require 'socket' 
require 'uri'
require 'erb'
require 'tempfile'
require 'cgi'

CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'png' => 'image/png',
  'jpg' => 'image/jpeg',
  'css' => 'text/css',
  'erb' => 'text/html'
}

def content_type(path)
  ext = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING.fetch(ext, 'application/octet-stream')
end

def requested_file(request_line)
  # Work out what file should be delivered, and expect it to be an html.erb unless told otherwise (for assets or static files)
  request_uri  = request_line.split(" ")[1]
  request_uri = '/index' if request_uri == '/'
  request_uri = "views#{request_uri}#{'.html.erb' unless request_uri.include? '.'}" unless request_uri.include? 'assets'

  path = URI.unescape(URI(request_uri).path)

  clean = []

  path.split("/").each do |part|
    next if part.empty? || part == '.'
    part == '..' ? clean.pop : clean << part
  end

  File.join('./app', *clean)
end

server = TCPServer.new('localhost', 8080)

loop do # to allow more than one page request over the server's lifetime  
  socket = server.accept
  request_line = socket.gets

  # Log the request to the console for debugging
  STDERR.puts request_line
  
  request_line = request_line.split('?')

  params = ''
  params = request_line[1].split(' ')[0] if request_line[1]
  params = params.split('&')
  
  params_hash = {}
  params.each do |param|
    param = param.split('=')
    params_hash[param[0]] = param[1]
  end
  
  path = requested_file(request_line[0])
  
  if File.exist?(path) && !File.directory?(path)
    response = '200 OK'
  else
    response = '404 Not Found'
    path = './app/errors/404.html'
  end

  File.open(path, "rb") do |file|
    tmp = Tempfile.new('temp.html') 
    
    success = tmp.write(ERB.new(file.read).result binding) rescue '500'
     
    
    if success == '500' # rework this so it ties in nicely with the 200/404/etc above
      response = '500 Internal Server Error'
      tmp.write("<strong>Uh oh.  Something broke.</strong><br/><br/>#{response}")
    end
      tmp.rewind  

  
    socket.print "HTTP/1.1 #{response} OK\r\n" +
                 "Content-Type: #{content_type(file)}\r\n" +
                 "Content-Length: #{tmp.size}\r\n" +
                 "Connection: close\r\n"

    socket.print "\r\n"
    IO.copy_stream(tmp, socket)    

    
    # write the contents of the file to the socket
    
    tmp.close
    tmp.unlink
  end


  socket.close
end
