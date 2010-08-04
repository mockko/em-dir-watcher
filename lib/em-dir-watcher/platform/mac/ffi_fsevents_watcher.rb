
require 'ffi'

module EMDirWatcher
module Platform
module Mac

module CarbonCore
    extend FFI::Library
    ffi_lib '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Versions/Current/CarbonCore'

    attach_function :CFStringCreateWithCString, [:pointer, :string, :int], :pointer
    KCFStringEncodingUTF8 = 0x08000100
    attach_function :CFStringGetLength, [:pointer, :pointer, :int, :pointer, :pointer, :pointer], :int

    attach_function :CFArrayCreate, [:pointer, :pointer, :int, :pointer], :pointer

    attach_function :CFRunLoopRun, :CFRunLoopRun, [], :void
    attach_function :CFRunLoopGetCurrent, [], :pointer
    attach_variable :kCFRunLoopDefaultMode, :pointer

    callback :FSEventStreamCallback, [:int], :void

    KFSEventStreamEventIdSinceNow = -1
    attach_function :FSEventStreamCreate, [:pointer, :FSEventStreamCallback, :pointer, :pointer, :long, :double, :int], :pointer
    attach_function :FSEventStreamScheduleWithRunLoop, [:pointer, :pointer, :pointer], :void
    attach_function :FSEventStreamStart, [:pointer], :void
    attach_function :FSEventStreamStop, [:pointer], :void
end

class FSEventStream
    
    KFSEventStreamEventFlagMustScanSubDirs = 0x1

    class StreamError < StandardError;
    end

    def initialize(paths, &block)
        raise ArgumentError, 'No callback block was specified.' unless block_given?
        paths.each { |path| raise ArgumentError, "The specified path (#{path}) does not exist." unless File.exist?(path) }

        handler = lambda do |stream, client_callback_info, number_of_events, paths_pointer, event_flags, event_ids|
            $stderr.puts "CHANGED!"
            block.call(['/'])
        end
        latency = 0.0
        flags = 0

        path_cfstring = CarbonCore.CFStringCreateWithCString nil, paths[0], CarbonCore::KCFStringEncodingUTF8
        # puts "path_cfstring = #{path_cfstring}"
        # puts "len = #{CarbonCore.CFStringGetLength(path_cfstring)}"

        paths_ptr = FFI::MemoryPointer.new(:pointer)
        paths_ptr.write_pointer path_cfstring
        paths_cfarray = CarbonCore.CFArrayCreate nil, paths_ptr, 1, nil
        # puts "paths_cfarray = #{paths_cfarray}"

        fsevent_stream = CarbonCore.FSEventStreamCreate nil, handler, nil, paths_cfarray, CarbonCore::KFSEventStreamEventIdSinceNow, 0.0, 0
        # puts "fsevent_stream = #{fsevent_stream}"

        # puts "CarbonCore.kCFRunLoopDefaultMode = #{CarbonCore.kCFRunLoopDefaultMode}"
        # puts "len = #{CarbonCore.CFStringGetLength(CarbonCore.kCFRunLoopDefaultMode)}"

        CarbonCore.FSEventStreamScheduleWithRunLoop fsevent_stream, CarbonCore.CFRunLoopGetCurrent, CarbonCore.kCFRunLoopDefaultMode

        CarbonCore.FSEventStreamStart fsevent_stream
    end
    
    def run_loop
        CarbonCore.CFRunLoopRun
    end

    def stop
        CarbonCore.FSEventStreamStop(@stream)
    end
end

end
end
end
