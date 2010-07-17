
require 'eventmachine'
require 'rbconfig'

module EMDirWatcher
    PLATFORM =
        case Config::CONFIG['target_os']
            when /mswin|mingw/ then 'Windows'
            else                    'NIX'
        end
end

require "em-dir-watcher/platform/#{EMDirWatcher::PLATFORM.upcase}"

module EMDirWatcher
    Watcher = Platform.const_get(PLATFORM)::Watcher

    def self.watch path, globs, &handler
        Watcher.new path, globs, &handler
    end
end

