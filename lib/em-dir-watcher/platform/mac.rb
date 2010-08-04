
require "em-dir-watcher/invokers/subprocess_invoker"

module EMDirWatcher
module Platform
module Mac

class Watcher

    attr_accessor :handler, :active

    def initialize path, inclusions, exclusions
        subprocess = lambda do |&output|
            require "em-dir-watcher/platform/mac/rubycocoa_watcher"
            stream = FSEventStream.new [path] do |changed_paths|
                changed_paths.each { |path| output.call path }
            end
            stream.run_loop
        end
        
        @invoker = EMDirWatcher::Invokers::SubprocessInvoker.new subprocess do |path|
            code, path = path[0], path[1..-1]
            if code == ?> || code == ?-
                refresh_subtree = (code == ?>)
                yield path, refresh_subtree
            end
        end
    end

    def stop
        @invoker.stop
    end

end
end
end
end
