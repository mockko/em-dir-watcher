
module EMDirWatcher
    Watcher = Platform.const_get(PLATFORM)::Watcher

    def self.watch path, inclusions=nil, exclusions=[]
        tree = Tree.new path, inclusions, exclusions
        Watcher.new path, inclusions, exclusions do |change_scope, refresh_subtree|
            for changed_path in tree.refresh! change_scope, true
                yield changed_path
            end
        end
    end
end
