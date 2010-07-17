$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'em-dir-watcher'

dir = (ARGV.empty? ? '.' : ARGV.shift)
globs = (ARGV.empty? ? ['**/*'] : ARGV)

EM.run {
    dw = EMDirWatcher.watch dir, globs do |path|
        if File.exists? path
            puts "Modified: #{path}"
        else
            puts "Deleted: #{path}"
        end
    end
    puts "Monitoring #{File.expand_path(dir)}..."
}
