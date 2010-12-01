require "socket"

require "rubygems"
require "rhook"

# Trace TCPSocket output data.
TCPSocket._rhook.hack(:write) do |inv|
  STDERR.print("> ", inv.args[0].inspect, "\n")
  inv.call
end

# Trace TCPSocket input data.
TCPSocket._rhook.hack(:read) do |inv|
  inv.call
  STDERR.print("< ", inv.returned.inspect, "\n")
  inv.returned
end


require "rack"
require "rack/handler/webrick"

th = Thread.start {
  Rack::Handler::WEBrick.run(lambda { |env|
    [200, {}, []]
  }, :Port => 9292)
}
sleep 1

sock = TCPSocket.new("localhost", 9292)
sock.print("GET / HTTP/1.0\n\n")
sock.flush

sock.read
