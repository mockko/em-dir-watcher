
module EMDirWatcher
    Watcher = Platform.const_get(PLATFORM)::Watcher

    DEFAULT_OPTIONS = {
        :exclude => [],
        :include_only => nil,
    }.freeze

    def self.watch path, options={}
        unless (invalid_keys = options.keys - DEFAULT_OPTIONS.keys).empty?
            raise StandardError, "Unsupported options given to EMDirWatcher.watch: " + invalid_keys.join(", ")
        end
        options = DEFAULT_OPTIONS.merge(options)

        tree = Tree.new path, options[:include_only], options[:exclude]
        Watcher.new path, options[:include_only], options[:exclude] do |change_scope, refresh_subtree|
            for changed_path in tree.refresh! change_scope, refresh_subtree
                yield changed_path
            end
        end
    end
end
