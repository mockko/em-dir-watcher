
require 'io/nonblock'

module EMDirWatcher
module Invokers

class SubprocessInvoker

    attr_reader :active
    attr_reader :input_handler
    attr_accessor :additional_delay

    def initialize subprocess, &input_handler
        @subprocess = subprocess
        @input_handler = input_handler
        @active = true
        @ready_to_use = false
        @ready_to_use_handlers = []
        @additional_delay = 0.1
        start_subprocess
    end

    def when_ready_to_use &ready_to_use_handler
      if @ready_to_use_handlers.nil?
          ready_to_use_handler.call()
      else
          @ready_to_use_handlers << ready_to_use_handler
      end
    end

    def stop
        @active = false
        kill
    end

    # private methods

    def ready_to_use!
        return if @ready_to_use
        @ready_to_use = true
        EM.add_timer @additional_delay do
            @ready_to_use_handlers.each { |handler| handler.call() }
            @ready_to_use_handlers = nil
        end
    end

    def kill
        if @io
            Process.kill 9, @io.pid
            Process.waitpid @io.pid
            @io = nil
        end
    end

    def start_subprocess
        io = open('|-', 'r')
        if io.nil?
            $stdout.sync = true
            ready  = lambda { puts }
            output = lambda { |single_line_string| puts single_line_string.strip }
            @subprocess.call ready, output
            exit
        end
        @io = io
        @io.nonblock = true

        @connection = EM.watch io do |conn|
            class << conn
                attr_accessor :invoker
                
                def notify_readable
                    @invoker.ready_to_use!
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
