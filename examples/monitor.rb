$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'em-dir-watcher'

dir = (ARGV.empty? ? '.' : ARGV.shift)
inclusions = ARGV.reject { |arg| arg =~ /^!/ }
inclusions = nil if inclusions == []
exclusions = ARGV.select { |arg| arg =~ /^!/ }.collect { |arg| arg[1..-1] }

EM.error_handler{ |e|
    puts "Error raised during event loop: #{e.class.name} #{e.message}"
    puts e.backtrace
}

EM.run {
    dw = EMDirWatcher.watch dir, :include_only => inclusions, :exclude => exclusions do |path|
        full_path = File.join(dir, path)
        if File.exists? full_path
            puts "Modified: #{path}"
        else
            puts "Deleted: #{path}"
        end
    end
    puts "Monitoring #{File.expand_path(dir)}..."
}
