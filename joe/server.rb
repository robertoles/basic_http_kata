require 'socket'
require 'uri'
require 'erb'

WEB_ROOT = "./"

def get_content_type(path)
  ext = File.extname(path)
  return "text/html"  if ext == ".html" or ext == ".htm"
  return "text/plain" if ext == ".txt"
  return "text/css"   if ext == ".css"
  return "image/jpeg" if ext == ".jpeg" or ext == ".jpg"
  return "image/gif"  if ext == ".gif"
  return "image/bmp"  if ext == ".bmp"
  return "text/plain" if ext == ".rb"
  return "text/xml"   if ext == ".xml"
  return "text/xml"   if ext == ".xsl"
  return "text/plain"
end

def requested_file(request)
  request_uri  = request.split(" ")[1]
  path         = URI.unescape(URI(request_uri).path)

  clean = []

  # Split the path into components
  parts = path.split("/")

  parts.each do |part|
    # skip any empty or current directory (".") path components
    next if part.empty? || part == '.'
    # If the path component goes up one directory level (".."),
    # remove the last clean component.
    # Otherwise, add the component to the Array of clean components
    part == '..' ? clean.pop : clean << part
  end

  # return the web root joined to the clean path
  File.join(WEB_ROOT, *clean)
end

def path_params(request)
  request_uri  = request.split(" ")[1]
  path         = request_uri
  params = path.split('?')[-1]
  params = params.split('&')

  Hash[params.each.map{ |p| p.split("=")}]
end

server = TCPServer.new('localhost', 8080)
www = Dir.new("www")

loop do
	socket = server.accept
	request = socket.gets
	next unless request
	path = requested_file(request)
	@params = path_params(request)
	response = nil

	if !path.split("/")[1]
		response = ""
		www.entries.each do |f|
			response += File.directory?(f) ? "/www/#{f}/\n" : "/www/#{f}\n"
		end
		socket.print 	"HTTP/1.1 200 OK\r\n" +
									"Content-Type: #{get_content_type(path)}\r\n" +
									"Content-Length: #{response.bytesize}\r\n" +
									"Connection: close\r\n"
		socket.print "\r\n"
		socket.print response
	elsif File.exists?(path) && !File.directory?(path)
    File.open(path, "rb") do |file|
      socket.print "HTTP/1.1 200 OK\r\n" +
                   "Content-Type: #{get_content_type(file)}\r\n" +
                   #"Content-Length: #{file.size}\r\n" +
                   "Connection: close\r\n"

      socket.print "\r\n"
      template = ERB.new File.new(file).read, nil, "%"
      socket.print template.result(binding)
    end

  else
    # respond with a 404 error code to indicate the file does not exist
    socket.print "HTTP/1.1 404 Not Found\r\n" +
                 "Content-Type: text/plain\r\n" +
                 "Connection: close\r\n"
	end

	socket.close
end