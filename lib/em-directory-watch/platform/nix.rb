
module EvDirectoryWatcher
module Platform
module NIX
class Watcher

    attr_accessor :handler, :active

    class << self
        def run_fssm_watcher path, globs
            require 'fssm'
            $stdout.sync = true
            report = proc { |b,r| puts File.join(b, r) }
            FSSM.monitor path, globs do
                create &report
                delete &report
                update &report
            end
        end
    end

    def initialize path, globs, &handler
        @path = path
        @globs = globs
        @handler = handler
        @active = true

        setup_listener
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
        io = open('|-', 'r')
        if io.nil?
            Watcher.run_fssm_watcher @path, @globs
            exit
        end
        @io = io

        @connection = EM.watch io do |conn|
            class << conn
                attr_accessor :watcher

                def notify_readable
                    path = @io.readline.strip
                    @watcher.handler.call path
                rescue EOFError
                    detach
                    @watcher.kill  # waitpid to cleanup zombie
                    if @watcher.active
                        EM.next_tick do
                            @watcher.setup_listener
                        end
                    end
                end

                def unbind
                    @watcher.kill
                end
            end
            conn.watcher = self
            conn.notify_readable = true
        end
    end

end
end
end
end

