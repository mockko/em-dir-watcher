$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'em-directory-watch'

EM.run {
    dw = EvDirectoryWatcher.watch '.', ['**/*'] do |path|
        if File.exists? path
            puts "Modified: #{path}"
        else
            puts "Deleted: #{path}"
        end
    end
#     EM.add_timer 3 do
#         puts "Stopping..."
#         dw.stop
#     end

#     EM.add_timer 3 do
#         puts "Stopping..."
#         EM.stop
#     end
    puts "EventMachine running..."
}
puts "Exit countdown..."
sleep 3
puts "Bye!"

