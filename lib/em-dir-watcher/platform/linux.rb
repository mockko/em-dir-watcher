require 'rb-inotify'
require 'io/nonblock'

module EMDirWatcher
module Platform
module Linux

class Watcher

  def initialize path, inclusions, exclusions
    @notifier = INotify::Notifier.new

    @notifier.watch(path, :recursive, :attrib, :modify, :create,
                    :delete, :delete_self, :moved_from, :moved_to,
                    :move_self) do |event|
      yield event.absolute_name
    end

    @conn = EM.watch @notifier.to_io do |conn|
      class << conn
        attr_accessor :notifier

        def notify_readable
          @notifier.process
        end
      end
      conn.notifier = @notifier
      conn.notify_readable = true
    end
  end

  def when_ready_to_use
      yield
  end

  def ready_to_use?; true; end

  def stop
    @notifier.close
  rescue SystemCallError
  end
end

end
end
end
