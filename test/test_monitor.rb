require 'helper'

class TestMonitor < Test::Unit::TestCase

    def setup
        FileUtils.rm_rf TEST_DIR
        FileUtils.mkdir_p TEST_DIR

        FileUtils.mkdir File.join(TEST_DIR, 'bar')
        FileUtils.mkdir File.join(TEST_DIR, 'bar', 'boo')

        FileUtils.touch File.join(TEST_DIR, 'aa')
        FileUtils.touch File.join(TEST_DIR, 'biz')
        FileUtils.touch File.join(TEST_DIR, 'zz')
        FileUtils.touch File.join(TEST_DIR, 'bar', 'foo')
        FileUtils.touch File.join(TEST_DIR, 'bar', 'biz')
        FileUtils.touch File.join(TEST_DIR, 'bar', 'biz.html')
        FileUtils.touch File.join(TEST_DIR, 'bar', 'boo', 'bizzz')

        @list = ['aa', 'biz', 'zz', 'bar/foo', 'bar/biz', 'bar/biz.html', 'bar/boo/bizzz'].sort
    end

    should "should report a deletion" do
        changed_paths = []
        stopped = false
        watcher = nil
        EM.run {
            watcher = EMDirWatcher.watch TEST_DIR, :include_only => ['/bar'], :exclude => ['*.html'] do |changed_path|
                changed_paths << changed_path
                EM.add_timer 0.2 do EM.stop end
            end
            watcher.when_ready_to_use do
                FileUtils.rm_rf File.join(TEST_DIR, 'bar')
                EM.add_timer 1 do EM.stop end
            end
        }
        watcher.stop
        assert_equal join(['bar/foo', 'bar/biz', 'bar/boo/bizzz'].sort), join(changed_paths.sort)
    end

    should "choke on invalid option keys" do
        assert_raise StandardError do
            EM.run {
                EMDirWatcher.watch TEST_DIR, :bogus_option => true
            }
        end
    end

end
