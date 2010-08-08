require 'helper'

class TestMonitor < Test::Unit::TestCase

    # A sufficiently reliable maximum file system change reporting lag, in seconds.
    # See README for explaination of its effect.
    UNIT_DELAY = 0.5

    def setup
        FileUtils.rm_rf TEST_DIR
        FileUtils.mkdir_p TEST_DIR
        FileUtils.rm_rf ALT_TEST_DIR
        FileUtils.mkdir_p ALT_TEST_DIR

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
        all_changed_paths = []
        stopped = false
        watcher = nil
        EM.run {
            watcher = EMDirWatcher.watch TEST_DIR, :include_only => ['/bar'], :exclude => ['*.html'] do |changed_paths|
                all_changed_paths += changed_paths
            end
            watcher.when_ready_to_use do
                FileUtils.rm_rf File.join(TEST_DIR, 'bar')
                EM.add_timer UNIT_DELAY do EM.stop end
            end
        }
        watcher.stop
        assert_equal join(['bar/foo', 'bar/biz', 'bar/boo/bizzz'].sort), join(all_changed_paths.sort)
    end

    should "choke on invalid option keys" do
        assert_raise StandardError do
            EM.run {
                EMDirWatcher.watch TEST_DIR, :bogus_option => true
            }
        end
    end

    should "report each change individually when using a zero grace period" do
        changed_1 = []
        changed_2 = []
        changed_cur = changed_1
        stopped = false
        watcher = nil
        EM.run {
            watcher = EMDirWatcher.watch TEST_DIR, :include_only => ['/bar'], :exclude => ['*.html'] do |changed_paths|
                changed_cur.push *changed_paths
            end
            watcher.when_ready_to_use do
                FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
                EM.add_timer 1 do
                    changed_cur = changed_2
                    FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'biz')
                    EM.add_timer 0.5 do EM.stop end
                end
            end
        }
        watcher.stop
        assert_equal 'bar/foo >> bar/biz', join(changed_1.sort) + " >> " + join(changed_cur.sort)
    end

    should "combine changes when using a non-zero grace period" do
        changed_1 = []
        changed_2 = []
        changed_cur = changed_1
        stopped = false
        watcher = nil
        EM.run {
            watcher = EMDirWatcher.watch TEST_DIR, :include_only => ['/bar'], :exclude => ['*.html'], :grace_period => 2*UNIT_DELAY do |changed_paths|
                changed_cur.push *changed_paths
            end
            watcher.when_ready_to_use do
                FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
                EM.add_timer UNIT_DELAY do
                    changed_cur = changed_2
                    FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'biz')
                    EM.add_timer 2*UNIT_DELAY do EM.stop end
                end
            end
        }
        watcher.stop
        assert_equal ' >> bar/biz, bar/foo', join(changed_1.sort) + " >> " + join(changed_cur.sort)
    end

    should "not report duplicate changes when using a non-zero grace period" do
        changed_1 = []
        changed_2 = []
        changed_cur = changed_1
        stopped = false
        watcher = nil
        EM.run {
            watcher = EMDirWatcher.watch TEST_DIR, :include_only => ['/bar'], :exclude => ['*.html'], :grace_period => 3*UNIT_DELAY do |changed_paths|
                changed_cur.push *changed_paths
            end
            watcher.when_ready_to_use do
                FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
                EM.add_timer UNIT_DELAY do
                    FileUtils.touch File.join(TEST_DIR, 'bar', 'foo')
                    EM.add_timer UNIT_DELAY do
                        changed_cur = changed_2
                        FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
                        FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'biz')
                        EM.add_timer 2*UNIT_DELAY do EM.stop end
                    end
                end
            end
        }
        watcher.stop
        assert_equal ' >> bar/biz, bar/foo', join(changed_1.sort) + " >> " + join(changed_cur.sort)
    end

    should "should report entire subtree as changed when a directory is moved away" do
        all_changed_paths = []
        stopped = false
        watcher = nil
        EM.run {
            watcher = EMDirWatcher.watch TEST_DIR, :include_only => ['/bar'], :exclude => ['*.html'] do |changed_paths|
                all_changed_paths += changed_paths
            end
            watcher.when_ready_to_use do
                FileUtils.mv File.join(TEST_DIR, 'bar'), ALT_TEST_DIR
                EM.add_timer UNIT_DELAY do EM.stop end
            end
        }
        watcher.stop
        assert_equal join(['bar/foo', 'bar/biz', 'bar/boo/bizzz'].sort), join(all_changed_paths.sort)
    end

    should "should report entire subtree as changed when a directory is moved in" do
        all_changed_paths = []
        stopped = false
        watcher = nil
        EM.run {
            watcher = EMDirWatcher.watch ALT_TEST_DIR, :exclude => ['*.html'] do |changed_paths|
                all_changed_paths += changed_paths
            end
            watcher.when_ready_to_use do
                FileUtils.mv File.join(TEST_DIR, 'bar'), ALT_TEST_DIR
                EM.add_timer UNIT_DELAY do EM.stop end
            end
        }
        watcher.stop
        assert_equal join(['bar/foo', 'bar/biz', 'bar/boo/bizzz'].sort), join(all_changed_paths.sort)
    end

end
