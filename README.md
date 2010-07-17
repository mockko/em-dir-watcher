em-dir-watcher: real directory monitoring for EventMachine
==========================================================

Employs FSEvents, inotify or Win32 Directory Change Notifications APIs under EventMachine. (Forks a subprocess for blocking watchers.)

Usage
-----

    require 'rubygems'
    require 'em-dir-watcher'

    EM.run {
        dw = EMDirWatcher.watch '.', ['**/*.css', 'lib/**/*.rb'] do |path|
            if File.exists? path
                puts "Modified: #{path}"
            else
                puts "Deleted: #{path}"
            end
        end
        puts "EventMachine running..."
    }

Run `examples/monitor.rb` to see it in action.

License
-------

Copyright (c) 2010 Andrey Tarantsov. Distributed under the MIT license. See LICENSE for details.
