# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{em-dir-watcher}
  s.version = "0.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrey Tarantsov", "Mikhail Gusarov"]
  s.date = %q{2010-08-09}
  s.description = %q{Directory watching support for EventMachine (fssm / win32-changenotify)}
  s.email = %q{andreyvit@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.md"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.md",
     "Rakefile",
     "VERSION",
     "examples/monitor.rb",
     "lib/em-dir-watcher.rb",
     "lib/em-dir-watcher/invokers/subprocess_invoker.rb",
     "lib/em-dir-watcher/monitor.rb",
     "lib/em-dir-watcher/platform/linux.rb",
     "lib/em-dir-watcher/platform/mac.rb",
     "lib/em-dir-watcher/platform/mac/ffi_fsevents_watcher.rb",
     "lib/em-dir-watcher/platform/mac/rubycocoa_watcher.rb",
     "lib/em-dir-watcher/platform/windows.rb",
     "lib/em-dir-watcher/platform/windows/monitor.rb",
     "lib/em-dir-watcher/platform/windows/path_to_ruby_exe.rb",
     "lib/em-dir-watcher/tree.rb",
     "test/helper.rb",
     "test/test_monitor.rb",
     "test/test_tree.rb",
     "testloop"
  ]
  s.homepage = %q{http://github.com/mockko/em-dir-watcher}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Directory watching support for EventMachine (fssm / win32-changenotify)}
  s.test_files = [
    "test/helper.rb",
     "test/test_monitor.rb",
     "test/test_tree.rb",
     "examples/monitor.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

