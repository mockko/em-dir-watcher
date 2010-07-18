
# this is only used when debugging Windows code on a Mac

$stdout.sync = true

require 'rubygems'
require 'socket'
require 'fssm'

port = ARGV[0].to_i
dir = ARGV[1]

socket = TCPSocket.open('127.0.0.1', port)

report_change = proc do |a, b|
    path = File.join(a, b)
    socket.puts path
end

begin
    FSSM.monitor dir do
        update(&report_change)
        create(&report_change)
        delete(&report_change)
    end
ensure
  cn.close
  socket.close
end
