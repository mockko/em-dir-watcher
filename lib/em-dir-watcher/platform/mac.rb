
require "em-dir-watcher/invokers/subprocess_invoker"

module EMDirWatcher
module Platform
module Mac

class Watcher

    STARTUP_DELAY = 0.5

    attr_accessor :handler, :active

    def initialize path, inclusions, exclusions
        subprocess = lambda do |ready, output|
            require "em-dir-watcher/platform/mac/rubycocoa_watcher"
            # require "em-dir-watcher/platform/mac/ffi_fsevents_watcher"
            stream = FSEventStream.new [path] do |changed_paths|
                changed_paths.each { |path| output.call path }
            end
            ready.call()
            stream.run_loop
        end
        
        @invoker = EMDirWatcher::Invokers::SubprocessInvoker.new subprocess do |path|
            code, path = path[0], path[1..-1]
            if code == ?> || code == ?-
                refresh_subtree = (code == ?>)
                yield path, refresh_subtree
            end
        end
        # Mac OS X seems to require this delay till it really starts listening for file system changes.
        # See README for explaination of the effect.
        @invoker.additional_delay = STARTUP_DELAY
    end

    def when_ready_to_use &ready_to_use_handler
        @invoker.when_ready_to_use &ready_to_use_handler
    end

    def ready_to_use?; true; end

    def stop
        @invoker.stop
    end

end
end
end
end
