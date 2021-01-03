###
# This class listens for incoming TCP connections from the GPS306A, and proxies the message to an HTTP endpoint
###

require 'net/http'

remote_host = 'data.gpstoolsonline.org'
remote_port = 80
remote_uri = 'http://data.gpstoolsonline.org/gps306a/msg'

listen_port = 3064
max_threads = 10000

threads = []

puts "starting server"
server = TCPServer.new(nil, listen_port)

while true
	# Start a new thread for every client connection.
	puts "waiting for connections"

	threads << Thread.new(server.accept) do |client_socket|

		begin
			puts "#{Thread.current}: got a client connection"
			
			# begin
			# 	server_socket = TCPSocket.new(remote_host, remote_port)
			# rescue Errno::ECONNREFUSED
			# 	client_socket.close
			# 	raise
			# end

			# puts "#{Thread.current}: connected to server at #{remote_host}:#{remote_port}"
			
			while true
				# Wait for data to be available on either socket.
				(ready_sockets, dummy, dummy) = IO.select([client_socket])
				
				begin
					ready_sockets.each do |socket|
						data = socket.readpartial(4096)
							
						# Read from client, write to server.
						puts "#{Thread.current}: client->server #{data.inspect}"
						req = Net::HTTP::Post.new(remote_uri)
						req.body = data

						res = Net::HTTP.start(remote_host, remote_port) {|http|
							http.request(req)
						}

						puts "Response: #{res}"
						client_socket.write "ok"

					end
				rescue EOFError
					break
				end
			end
		rescue StandardError => e
			puts "Thread #{Thread.current} got exception #{e.inspect}"
		end

		puts "#{Thread.current}: closing the connections"
		client_socket.close rescue StandardError
		server_socket.close rescue StandardError
	end

	# Clean up the dead threads, and wait until we have available threads.
	puts "#{threads.size} threads running"
	threads = threads.select { |t| t.alive? ? true : (t.join; false) }
	while threads.size >= max_threads
		sleep 1
		threads = threads.select { |t| t.alive? ? true : (t.join; false) }
	end
end