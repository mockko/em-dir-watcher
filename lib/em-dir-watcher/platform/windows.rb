
require File.join(File.dirname(__FILE__), 'windows', 'path_to_ruby_exe')

module EMDirWatcher
module Platform
module Windows

module TcpHandler
    attr_accessor :watcher

    def post_init
        @data_received = ""
    end

    def receive_data data
        @data_received << data
        while line = @data_received.slice!(/^[^\n]*[\n]/m)
            @watcher.path_changed line.strip
        end
    end
end

class Watcher

    def initialize path, globs, &handler
        @path = path
        @globs = globs
        @handler = handler
        @active = true

        start_server
        setup_listener
    end

    def start_server
        @server = EM.start_server '127.0.0.1', 0, TcpHandler do |server|
            server.watcher = self
        end
        @server_port, _ = Socket.unpack_sockaddr_in(EM::get_sockname @server)
        puts "Server running on port #{@server_port}"
    end

    def stop_server
        if @server
            EM.stop_server @server
            @server = nil
        end
    end

    def stop
        @active = false
        kill
    end

    def kill
        if @io
            Process.kill 'TERM', @io.pid 
            Process.waitpid @io.pid
            @io = nil
        end
    end

    def setup_listener
        path_to_script = File.join(File.dirname(__FILE__), 'windows', 'monitor.rb')
        path_to_ruby_exe = 'ruby'
        @io = IO.popen(path_to_ruby_exe + " " + path_to_script + " #{@server_port} " + File.expand_path(@path))
    end

    def path_changed path
        @handler.call path
    end

    def listener_died
        kill  # waitpid to cleanup zombie
        if @active
            EM.next_tick do
                setup_listener
            end
        end
    end

end
end
end
end

