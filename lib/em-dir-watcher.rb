
require 'eventmachine'
require 'rbconfig'

module EMDirWatcher
    PLATFORM = ENV['EM_DIR_WATCHER_PLATFORM'] ||
        case Config::CONFIG['target_os']
            when /mswin|mingw/ then 'Windows'
            when /darwin/      then 'Mac'
            when /linux/       then 'Linux'
            else                    'NIX'
        end
end

require "em-dir-watcher/tree"
require "em-dir-watcher/platform/#{EMDirWatcher::PLATFORM.downcase}"
require "em-dir-watcher/monitor"
