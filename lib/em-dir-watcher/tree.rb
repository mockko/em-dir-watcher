
module EMDirWatcher

class Entry
  
  attr_reader :relative_path
  
  def initialize full_path, relative_path
    @full_path = full_path
    @relative_path = relative_path
  end
  
  def entries
    (Dir.entries(@full_path) - ['.', '..']).collect do |entry|
      entry_relative_path = if @relative_path.empty? then entry else File.join(@relative_path, entry) end
      Entry.new File.join(@full_path, entry), entry_relative_path
    end
  end

  def recursive_file_entries
    if FileTest.directory? @full_path
      entries.collect { |entry| entry.recursive_file_entries }.flatten
    else
      self
    end
  end

end

# Computes fine-grained (per-file) change events for a given directory tree,
# using coarse-grained (per-subtree) events for optimization.
class Tree

  def initialize full_path
    @root_entry = Entry.new full_path, ''
  end
  
  def full_file_list
    @root_entry.recursive_file_entries.collect { |entry| entry.relative_path }
  end

end
end
