
require 'osx/foundation'
OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'

module EMDirWatcher
module Platform
module Mac

class FSEventStream
    
    KFSEventStreamEventFlagMustScanSubDirs = 0x1

    class StreamError < StandardError;
    end

    def initialize(paths, &block)
        raise ArgumentError, 'No callback block was specified.' unless block_given?
        paths.each { |path| raise ArgumentError, "The specified path (#{path}) does not exist." unless File.exist?(path) }

        callback = Proc.new do |stream, client_callback_info, number_of_events, paths_pointer, event_flags, event_ids|
            paths_pointer.regard_as('*')
            # event_flags.regard_as('*')
            events = []
            number_of_events.times {|i|
                flags = event_flags[i]
                code = if (flags & KFSEventStreamEventFlagMustScanSubDirs) == KFSEventStreamEventFlagMustScanSubDirs then '>' else '-' end
                events << code + paths_pointer[i].to_s
            }
            block.call(events)
        end
        latency = 0.0
        flags = 0
        @stream = OSX.FSEventStreamCreate(OSX::KCFAllocatorDefault, callback, nil, paths, OSX::KFSEventStreamEventIdSinceNow, latency, flags)
        raise(StreamError, 'Unable to create FSEvents stream.') unless @stream
        OSX.FSEventStreamScheduleWithRunLoop(@stream, OSX.CFRunLoopGetCurrent, OSX::KCFRunLoopDefaultMode)
        ok = OSX.FSEventStreamStart(@stream)
        raise(StreamError, 'Unable to start FSEvents stream.') unless ok
    end
    
    def run_loop
        OSX.CFRunLoopRun
    end

    def stop
        OSX.FSEventStreamStop(@stream)
    end
end

end
end
end
