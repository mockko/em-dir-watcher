require 'set'

module EMDirWatcher
    Watcher = Platform.const_get(PLATFORM)::Watcher

    DEFAULT_OPTIONS = {
        :exclude => [],
        :include_only => nil,
        :grace_period => 0.0,
    }.freeze

    INFINITELY_SMALL_PERIOD = 0.001

    def self.watch path, options={}
        unless (invalid_keys = options.keys - DEFAULT_OPTIONS.keys).empty?
            raise StandardError, "Unsupported options given to EMDirWatcher.watch: " + invalid_keys.join(", ")
        end
        options = DEFAULT_OPTIONS.merge(options)
        grace_period = options[:grace_period]

        tree = Tree.new path, options[:include_only], options[:exclude]

        pending_refresh_requests = Set.new
        process_pending_refresh_requests_scheduled = false

        process_pending_refresh_requests = lambda do
            process_pending_refresh_requests_scheduled = false
            changed_paths = Set.new
            pending_refresh_requests.each do |change_scope, refresh_subtree|
                changed_paths += tree.refresh! change_scope, refresh_subtree
            end
            yield changed_paths.to_a unless changed_paths.empty?
        end

        Watcher.new path, options[:include_only], options[:exclude] do |change_scope, refresh_subtree|
            pending_refresh_requests << [change_scope, refresh_subtree]
            if grace_period <= INFINITELY_SMALL_PERIOD
                process_pending_refresh_requests.call
            else
                unless process_pending_refresh_requests_scheduled
                    EM.add_timer grace_period, &process_pending_refresh_requests
                    process_pending_refresh_requests_scheduled = true
                end
            end
        end
    end
end
