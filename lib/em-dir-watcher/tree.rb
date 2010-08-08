
require 'set'
require 'pathname'

module EMDirWatcher

class Entry

  attr_reader :relative_path

  def initialize tree, relative_path, ancestor_matches_inclusions
    @tree = tree
    @matches_inclusions = ancestor_matches_inclusions || @tree.includes?(relative_path)
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
      new_entries[entry_name] = @entries[entry_name] || Entry.new(@tree, entry_relative_path, @matches_inclusions)
    end
    new_entries
  end

  def refresh_file! changed_relative_paths
    if @matches_inclusions
      used_to_be_file, @is_file = @is_file, compute_is_file
      previous_file_mtime, @file_mtime = @file_mtime, compute_file_mtime
      if used_to_be_file
        changed_relative_paths << @relative_path if not @is_file or previous_file_mtime != @file_mtime
      elsif @is_file
        changed_relative_paths << @relative_path
      end
    end
  end

  def refresh! changed_relative_paths, refresh_subtree
    refresh_file! changed_relative_paths
    old_entries, @entries = @entries, compute_entries

    if refresh_subtree
        entries_to_refresh = Set.new(@entries.values) + Set.new(old_entries.values)
        entries_to_refresh.each { |entry| entry.refresh! changed_relative_paths, true }
    else
        new_set, old_set = Set.new(@entries.values), Set.new(old_entries.values)
        removed_entries, added_entries = old_set - new_set, new_set - old_set
        still_existing_entries = old_set - removed_entries
        added_or_removed_entries = added_entries + removed_entries

        added_or_removed_entries.each { |entry| entry.refresh!      changed_relative_paths, true }
        still_existing_entries.each   { |entry| entry.refresh_file! changed_relative_paths }
    end
  end

  def scoped_refresh! changed_relative_paths, relative_scope, refresh_subtree
    if relative_scope.size == 0
      refresh! changed_relative_paths, refresh_subtree
    else
      entry_name, children_relative_scope = relative_scope[0], relative_scope[1..-1]
      entry_relative_path = relative_path_of entry_name
      return if @tree.excludes? entry_relative_path
      entry = (@entries[entry_name] ||= Entry.new(@tree, entry_relative_path, @matches_inclusions))
      entry.scoped_refresh! changed_relative_paths, children_relative_scope, refresh_subtree
      if relative_scope.size == 1
          @entries.delete entry_name unless entry.exists?
      end
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
    @glob = glob.gsub(%r-^/+-, '')
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
  attr_reader :inclusions
  attr_reader :exclusions
  
  def self.parse_matchers matcher_expressions
    matcher_expressions.collect do |expr|
      if Regexp === expr
        RegexpMatcher.new expr
      elsif expr.include? '/'
        PathGlobMatcher.new expr
      else
        NameGlobMatcher.new expr
      end
    end
  end

  def self.resolve_real_path_where_possible expanded_path
    Pathname.new(expanded_path).realpath().to_s
  rescue Errno::ENOENT
    dirname, basename = File.dirname(expanded_path), File.basename(expanded_path)
    return expanded_path if dirname == '/' || dirname == '.'
    return File.join(resolve_real_path_where_possible(dirname), basename)
  end

  def initialize full_path, inclusions=nil, exclusions=[]
    @full_path = self.class.resolve_real_path_where_possible(File.expand_path(full_path))
    self.inclusions = inclusions
    self.exclusions = exclusions
    @root_entry = Entry.new self, '', false
    @root_entry.refresh! [], true
  end

  def refresh! scope=nil, refresh_subtree=true
    scope = self.class.resolve_real_path_where_possible(File.expand_path(scope || @full_path))

    scope_with_slash     = File.join(scope, '')
    full_path_with_slash = File.join(@full_path, '')
    return [] unless scope_with_slash.downcase[0..full_path_with_slash.size-1] == full_path_with_slash.downcase

    relative_scope = (scope[full_path_with_slash.size..-1] || '').split('/')
    relative_scope = relative_scope.reject { |item| item == '' }

    changed_relative_paths = []
    @root_entry.scoped_refresh! changed_relative_paths, relative_scope, refresh_subtree
    changed_relative_paths.sort
  end

  def includes? relative_path
    @inclusion_matchers.nil? || @inclusion_matchers.any? { |matcher| matcher.matches? relative_path }
  end

  def excludes? relative_path
    @exclusion_matchers.any? { |matcher| matcher.matches? relative_path }
  end

  def full_file_list
    @root_entry.recursive_file_entries.collect { |entry| entry.relative_path }.sort
  end

private

  def inclusions= new_inclusions
    @inclusions = new_inclusions
    @inclusion_matchers = new_inclusions && self.class.parse_matchers(new_inclusions)
  end

  def exclusions= new_exclusions
    @exclusions = new_exclusions
    @exclusion_matchers = self.class.parse_matchers(new_exclusions)
  end

end
end
