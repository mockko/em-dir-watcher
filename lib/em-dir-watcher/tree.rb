
require 'set'

module EMDirWatcher

class Entry

  attr_reader :relative_path

  def initialize tree, relative_path
    @tree = tree
    @relative_path = relative_path
    @is_file = false
    @file_mtime = Time.at(0)
    @entries = {}
  end

  def full_path
    if @relative_path.empty? then @tree.full_path else File.join(@tree.full_path, @relative_path) end
  end

  def exists?
    File.exists? full_path
  end

  def compute_is_file
    FileTest.file? full_path
  end

  def compute_file_mtime
    if FileTest.symlink?(full_path) then Time.at(0) else File.mtime(full_path) end
  rescue Errno::ENOENT, Errno::ENOTDIR
    Time.at(0)
  end

  def compute_entry_names
    Dir.entries(full_path) - ['.', '..']
  rescue Errno::ENOENT, Errno::ENOTDIR
    []
  end

  def relative_path_of entry_name
    if @relative_path.empty? then entry_name else File.join(@relative_path, entry_name) end
  end

  def compute_entries
    new_entries = {}
    compute_entry_names.each do |entry_name|
      entry_relative_path = relative_path_of entry_name
      next if @tree.excludes? entry_relative_path
      new_entries[entry_name] = @entries[entry_name] || Entry.new(@tree, entry_relative_path)
    end
    new_entries
  end

  def refresh! changed_relative_paths
    used_to_be_file, @is_file = @is_file, compute_is_file
    previous_file_mtime, @file_mtime = @file_mtime, compute_file_mtime
    if used_to_be_file
      changed_relative_paths << @relative_path if not @is_file or previous_file_mtime != @file_mtime
    elsif @is_file
      changed_relative_paths << @relative_path
    end
    old_entries, @entries = @entries, compute_entries
    (Set.new(@entries.values) + Set.new(old_entries.values)).each { |entry| entry.refresh! changed_relative_paths }
  end

  def scoped_refresh! changed_relative_paths, relative_scope
    if relative_scope.size == 0
      refresh! changed_relative_paths
    else
      entry_name, children_relative_scope = relative_scope[0], relative_scope[1..-1]
      entry_relative_path = relative_path_of entry_name
      return if @tree.excludes? entry_relative_path
      entry = (@entries[entry_name] ||= Entry.new(@tree, entry_relative_path))
      entry.scoped_refresh! changed_relative_paths, children_relative_scope
      @entries.delete entry_name unless entry.exists?
    end
  end

  def recursive_file_entries
    if @is_file
      self
    else
      @entries.values.collect { |entry| entry.recursive_file_entries }.flatten
    end
  end

end

class RegexpMatcher
  def initialize re
    @re = re
  end
  def matches? relative_path
    relative_path =~ @re
  end
end

class PathGlobMatcher
  def initialize glob
    @glob = glob
  end
  def matches? relative_path
    File.fnmatch?(@glob, relative_path)
  end
end

class NameGlobMatcher
  def initialize glob
    @glob = glob
  end
  def matches? relative_path
    File.fnmatch?(@glob, File.basename(relative_path))
  end
end

# Computes fine-grained (per-file) change events for a given directory tree,
# using coarse-grained (per-subtree) events for optimization.
class Tree

  attr_reader :full_path
  attr_reader :excludes

  def initialize full_path, exclusions=[]
    @full_path = File.expand_path(full_path)
    self.excludes = exclusions
    @root_entry = Entry.new self, ''
    @root_entry.refresh! []
  end

  def excludes= new_excludes
    @excludes = new_excludes
    @exclude_matchers = new_excludes.collect do |exclusion|
      if Regexp === exclusion
        RegexpMatcher.new exclusion
      elsif exclusion.include? '/'
        PathGlobMatcher.new exclusion
      else
        NameGlobMatcher.new exclusion
      end
    end
  end

  def refresh! scope=nil
    scope = File.expand_path(scope || @full_path)

    scope_with_slash     = File.join(scope, '')
    full_path_with_slash = File.join(@full_path, '')
    return [] unless scope_with_slash.downcase[0..full_path_with_slash.size-1] == full_path_with_slash.downcase

    relative_scope = (scope[full_path_with_slash.size..-1] || '').split('/')
    relative_scope = relative_scope.reject { |item| item == '' }

    changed_relative_paths = []
    @root_entry.scoped_refresh! changed_relative_paths, relative_scope
    changed_relative_paths.sort
  end

  def excludes? relative_path
    @exclude_matchers.any? { |matcher| matcher.matches? relative_path }
  end

  def full_file_list
    @root_entry.recursive_file_entries.collect { |entry| entry.relative_path }.sort
  end

end
end
