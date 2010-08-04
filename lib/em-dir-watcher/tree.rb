
module EMDirWatcher

class Entry
  
  attr_reader :relative_path
  
  def initialize tree, relative_path
    @tree = tree
    @relative_path = relative_path
  end

  def full_path
    if @relative_path.empty? then @tree.full_path else File.join(@tree.full_path, @relative_path) end
  end

  def entries
    (Dir.entries(full_path) - ['.', '..']).collect do |entry|
      entry_relative_path = if @relative_path.empty? then entry else File.join(@relative_path, entry) end
      next nil if @tree.excludes? entry_relative_path
      Entry.new @tree, entry_relative_path
    end.compact
  end

  def recursive_file_entries
    if FileTest.directory? full_path
      entries.collect { |entry| entry.recursive_file_entries }.flatten
    else
      self
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

  def initialize full_path
    @full_path = full_path
    @root_entry = Entry.new self, ''
    self.excludes = []
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

  def excludes? relative_path
    @exclude_matchers.any? { |matcher| matcher.matches? relative_path }
  end

  def full_file_list
    @root_entry.recursive_file_entries.collect { |entry| entry.relative_path }.sort
  end

end
end
