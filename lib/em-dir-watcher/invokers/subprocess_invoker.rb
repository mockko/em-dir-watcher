
require 'io/nonblock'

module EMDirWatcher
module Invokers

class SubprocessInvoker

    attr_reader :active
    attr_reader :input_handler

    def initialize subprocess, &input_handler
        @subprocess = subprocess
        @input_handler = input_handler
        @active = true
        start_subprocess
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

    def start_subprocess
        io = open('|-', 'r')
        if io.nil?
            $stdout.sync = true
            puts
            @subprocess.call do |single_line_string|
                puts single_line_string.strip
            end
            exit
        end
        @io = io
        @io.readline
        @io.nonblock = true

        @connection = EM.watch io do |conn|
            class << conn
                attr_accessor :invoker
                
                def notify_readable
                    @data_received ||= ""
                    @data_received << @io.read
                    while line = @data_received.slice!(/^[^\n]*[\n]/m)
                        @invoker.input_handler.call line.strip
                    end
                rescue EOFError
                    detach
                    @invoker.kill  # waitpid to cleanup zombie
                    if @invoker.active
                        EM.next_tick do
                            @invoker.start_subprocess
                        end
                    end
                end

                def unbind
                    @invoker.kill
                end
            end
            conn.invoker = self
            conn.notify_readable = true
        end
    end

end

end
end
