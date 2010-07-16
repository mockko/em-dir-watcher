
require 'eventmachine'
require 'rbconfig'

module EvDirectoryWatcher
    PLATFORM =
        case Config::CONFIG['target_os']
            when /mswin|mingw/ then 'Windows'
            else                    'NIX'
        end
end

require "em-directory-watch/platform/#{EvDirectoryWatcher::PLATFORM.upcase}"

module EvDirectoryWatcher
    Watcher = Platform.const_get(PLATFORM)::Watcher

    def self.watch path, globs, &handler
        Watcher.new path, globs, &handler
    end
end

