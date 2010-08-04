$stdout.sync = true
require 'rubygems'
require 'socket'
require 'win32/changenotify'

port = ARGV[0].to_i
dir = ARGV[1]
CN = Win32::ChangeNotify
cn = CN.new(dir, true, CN::FILE_NAME | CN::DIR_NAME | CN::LAST_WRITE)

socket = TCPSocket.open('127.0.0.1', port)

begin
  cn.wait do |events|
    events.each do |event|
      socket.puts event.file_name
    end
  end
ensure
  cn.close
  socket.close
end
