em-dir-watcher: sane cross-platform file system change monitoring for Event Machine
===================================================================================

Compatible with Ruby 1.8+

Supported platforms:

* Mac OS X: employs FSEvents API via Ruby Cocoa. To support Ruby 1.8, forks a separate watcher process and communicates with it via pipes. (Ruby 1.9 should use threads instead, but this hasn't been implemented yet.)

* Linux: employs inotify via rb-inotify gem. This backend is nicest of all because inotify uses file descriptors and thus can be monitored from within Event Machine reactor.

* Windows: employs Directory Change Notifications API via win32-changenotify. To support Ruby 1.8, forks a separate watcher process and communicates with it via sockets. (We'd love to communicate via pipes, but couldn't figure a way to do it in a Event Machine-friendly way. Also we'd love to use threads on Ruby 1.9, but not there yet.)

* There is no fallback polling backend at the moment. Please contribute it if you need one.


Why not FSSM or Directory Watcher?
--------------------------------------

FSSM rescans the entire directory tree on each change, so it has about 0.5 sec lag on average-sized projects. Em-dir-watcher only rescans the changed subdirectories (on all systems), and avoids rescanning subtrees on the systems that support non-subtree notifications (Mac, Linux). We'd love to see our `Tree` class used in fssm — this should be an easy change.

Also, fssm does not know anything about Event Machine, so has to be run in a separate process/thread even on the systems that are reactor-friendly (i.e. Linux). Em-dir-watcher uses `EM.watch` to listen to inotify events on Linux.

DirectoryWatcher's Event Machine edition uses `EM.watchFile`, which runs out of max open file limit pretty quickly. Also it employs polling to catch added or removed files, and has to walk the entire directory tree every time. Em-dir-watcher uses native backends to watch for file system changes (just like FSSM), and finds added or removed files just as quickly as modified ones.

Besides, both fssm and directory_watcher do not support exclusions, and thus will walk, update and keep the entire tree in memory including the subfolders you don't need. Em-dir-watcher never walks excluded subfolders, so you can exclude the stuff you don't need to watch to further improve the performance.


Installation
------------

Mac:

    sudo gem install em-dir-watcher

Linux:

    sudo gem install rb-inotify em-dir-watcher

Windows:

    gem install win32-changenotify em-dir-watcher


Usage
-----

    require 'rubygems'
    require 'em-dir-watcher'

    EM.run {
        dw = EMDirWatcher.watch '.' do |paths|
            paths.each do |path|
                if File.exists? path
                    puts "Modified: #{path}"
                else
                    puts "Deleted: #{path}"
                end
            end
        end
        puts "EventMachine running..."
    }

Run `examples/monitor.rb` to see it in action.


EMDirWatcher.watch
------------------

`EMDirWatcher.watch` accepts a path and an options hash:

    EMDirWatcher.watch File.expand_path('~/my_project'),
        :include_only => ['*.html', '*.css', '*.js'],
        :exclude => ['~*', 'vendor/plugins'],
        :grace_period => 0.2

It returns an object that has a single `stop` method:

    dw = EMDirWatcher.watch File.expand_path('~/my_project')
    ...
    dw.stop


Inclusions and exclusions
-------------------------

If the list of inclusions is `nil` (the default), all files are included. Otherwise it has to be an array, and specifies a list of patterns to monitor. Each pattern is either a name glob, a path glob or a path regexp (more on this later).

The list of exclusions defaults to an empty array, and specifies the list of patterns to exclude. Each pattern is either a name glob, a path glob or a path regexp. If a path matches both an inclusion and an exclusion filter, it is excluded.

Patterns are inspired by Git's `.gitignore` conventions. Each pattern can be one of the following:

* A string that does not contain a slash is treated as a shell-style glob and is matched against file **base names.** For example, you can use `*.html` to match HTML files in any directory, or `~*` to match temporary files in any directory.

* A string that contains a slash is treated as a shell-style glob and is matched against file **paths** (relative to the monitored directory). For example, you can use `lib/rake` to match all files in `lib/rake` directory, or `/vendor` to match a `vendor` directory.

* A regexp is matched against file relative paths. For example, you can use `/[A-Z]/` to match all files and directories that contain upper-case characters in their name.


Grace period
------------

Use `:grace_period => 1.0` to combine the changes together if they occur in quick succession. This, for example, may be used to avoid starting a build while some files are still being updated from a repository.

The default grace period is `0`, which means that changes are reported immediately when they occur.


Hacking
-------

Required software:

    sudo gem install jeweler shoulda

To run the tests, use:

    rake test

This is expected to work on all platforms and shouldn't give any failures, EXCEPT that on a Mac spurious test failures occur in about 1–3 of 20 test runs, and we are unable to get rid of them.

You can use `./testloop` script to run the tests multiple times in a row to check for unreliable behaviors.

To give a more context on Mac test failures, two constants that have an effect on them are `STARTUP_DELAY` in `lib/em-dir-watcher/platform/mac.rb` and `UNIT_DELAY` in `tests/test_monitor.rb`. We've settled on a sweet spot of `0.5`/`0.5`, which gives a 5%–15% failure rate. Increasing them to `1.0`/`1.0` still results in the same failure rate. Decreasing them to `0.2`/`0.2` results in 30% failed test runs.

You can use `rake rcov` to check code coverage info. Currently `tree.rb` and `monitor.rb` have 100% test coverage, `mac.rb` has 80% coverage, `linux.rb` should have about 100% coverage and `windows.rb` should have about 80% coverage (the last two were not measured).


Help Wanted aka TODO
--------------------

If you find yourself using this gem, consider implementing one of the following functions:

* Ruby 1.9-friendly thread-based Mac backend
* Ruby 1.9-friendly thread-based Windows backend
* FFI-based Mac backend — there is no need to employ Ruby Cocoa monster just to invoke a handful of functions; a nearly-working version is in `lib/em-dir-watcher/platform/mac/ffi_fsevents_watcher.rb`, just needs some final touches
* polling-based fallback backend for the folks on funny operating systems (from FreeBSD to Solaris to HP UX :)
* use Mac OS X's FSEvents native grace period implementation


License
-------

Copyright © 2010 Andrey Tarantsov, Mikhail Gusarov.

Distributed under the MIT license. See LICENSE for details.
