require 'helper'
require 'fileutils'
require 'eventmachine'

class TestTreeFileList < Test::Unit::TestCase

  def setup
    FileUtils.rm_rf TEST_DIR
    FileUtils.mkdir_p TEST_DIR
  end

  should "should be empty for an empty directory" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    assert_equal "", @tree.full_file_list.join(", ").strip
  end

  should "should return a single file" do
    FileUtils.touch File.join(TEST_DIR, 'foo')

    @tree = EMDirWatcher::Tree.new TEST_DIR
    assert_equal "foo", @tree.full_file_list.join(", ").strip
  end

  should "should return a file in a subdirectory" do
    FileUtils.mkdir File.join(TEST_DIR, 'bar')
    FileUtils.touch File.join(TEST_DIR, 'bar', 'foo')

    @tree = EMDirWatcher::Tree.new TEST_DIR
    assert_equal "bar/foo", @tree.full_file_list.join(", ").strip
  end

  should "should return a sorted list of files" do
    FileUtils.touch File.join(TEST_DIR, 'aa')
    FileUtils.touch File.join(TEST_DIR, 'zz')
    FileUtils.mkdir File.join(TEST_DIR, 'bar')
    FileUtils.touch File.join(TEST_DIR, 'bar', 'foo')

    @tree = EMDirWatcher::Tree.new TEST_DIR
    assert_equal "aa, bar/foo, zz", @tree.full_file_list.join(", ").strip
  end

end

class TestTreeInclusions < Test::Unit::TestCase

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

  should "ignore files not included by path" do
    @tree = EMDirWatcher::Tree.new TEST_DIR, ['/bar']
    assert_equal join(['bar/foo', 'bar/biz', 'bar/biz.html', 'bar/boo/bizzz'].sort), join(@tree.full_file_list)
  end

  should "ignore files not included by extension glob" do
    @tree = EMDirWatcher::Tree.new TEST_DIR, ['*.html']
    assert_equal join(['bar/biz.html'].sort), join(@tree.full_file_list)
  end

end

class TestTreeExclusions < Test::Unit::TestCase

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

  should "ignore a single file excluded by path" do
    @tree = EMDirWatcher::Tree.new TEST_DIR, nil, ['bar/biz']
    assert_equal join(@list - ['bar/biz']), join(@tree.full_file_list)
  end

  should "ignore files excluded by name" do
    @tree = EMDirWatcher::Tree.new TEST_DIR, nil, ['biz']
    assert_equal join(@list - ['biz', 'bar/biz']), join(@tree.full_file_list)
  end

  should "ignore files excluded by name glob" do
    @tree = EMDirWatcher::Tree.new TEST_DIR, nil, ['biz*']
    assert_equal join(@list - ['biz', 'bar/biz', 'bar/biz.html', 'bar/boo/bizzz']), join(@tree.full_file_list)
  end

  should "ignore a directory excluded by name glob" do
    @tree = EMDirWatcher::Tree.new TEST_DIR, nil, ['bo*']
    assert_equal join(@list - ['bar/boo/bizzz']), join(@tree.full_file_list)
  end

  should "ignore a files and directories excluded by regexp" do
    @tree = EMDirWatcher::Tree.new TEST_DIR, nil, [/b/]
    assert_equal join(['aa', 'zz']), join(@tree.full_file_list)
  end

end

class TestTreeInclusionsWithExclusions < Test::Unit::TestCase

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

  should "ignore files that match both inclusions and exclusions" do
    @tree = EMDirWatcher::Tree.new TEST_DIR, ['/bar'], ['*.html']
    assert_equal join(['bar/foo', 'bar/biz', 'bar/boo/bizzz'].sort), join(@tree.full_file_list)
  end

end

class TestTreeRefreshing < Test::Unit::TestCase

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

  should "no changes when nothing has changed" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    changed_paths = @tree.refresh!
    assert_equal "", join(changed_paths)
    assert_equal join(@list), join(@tree.full_file_list)
  end

  should "single file modification" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    sleep 1
    FileUtils.touch File.join(TEST_DIR, 'bar', 'foo')
    changed_paths = @tree.refresh!
    assert_equal join(['bar/foo']), join(changed_paths)
  end

  should "single file deletion" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.rm File.join(TEST_DIR, 'bar', 'biz')
    changed_paths = @tree.refresh!
    assert_equal join(['bar/biz']), join(changed_paths)
  end

  should "single directory deletion" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.rm_rf File.join(TEST_DIR, 'bar')
    changed_paths = @tree.refresh!
    assert_equal join(['bar/foo', 'bar/biz', 'bar/biz.html', 'bar/boo/bizzz'].sort), join(changed_paths)
  end

  should "single file creation" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.touch File.join(TEST_DIR, 'bar', 'miz')
    changed_paths = @tree.refresh!
    assert_equal join(['bar/miz']), join(changed_paths)
  end

  should "single directory creation" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.mkdir File.join(TEST_DIR, 'bar', 'koo')
    FileUtils.touch File.join(TEST_DIR, 'bar', 'koo', 'aaa')
    FileUtils.touch File.join(TEST_DIR, 'bar', 'koo', 'zzz')
    changed_paths = @tree.refresh!
    assert_equal join(['bar/koo/aaa', 'bar/koo/zzz'].sort), join(changed_paths)
  end

  should "not report changes on empty directory creation" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.mkdir File.join(TEST_DIR, 'bar', 'koo')
    changed_paths = @tree.refresh!
    assert_equal "", join(changed_paths)
  end

  should "files turned into a directory" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.rm File.join(TEST_DIR, 'bar', 'foo')
    FileUtils.mkdir File.join(TEST_DIR, 'bar', 'foo')
    FileUtils.touch File.join(TEST_DIR, 'bar', 'foo', 'aaa')
    FileUtils.touch File.join(TEST_DIR, 'bar', 'foo', 'zzz')
    changed_paths = @tree.refresh!
    assert_equal join(['bar/foo', 'bar/foo/aaa', 'bar/foo/zzz'].sort), join(changed_paths)
  end

  should "directory turned into a file" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'boo')
    FileUtils.touch File.join(TEST_DIR, 'bar', 'boo')
    changed_paths = @tree.refresh!
    assert_equal join(['bar/boo/bizzz', 'bar/boo'].sort), join(changed_paths)
  end

  should "avoid traversing excluded directories" do
    @tree = EMDirWatcher::Tree.new TEST_DIR, nil, ['death']
    FileUtils.ln_s(TEST_DIR, File.join(TEST_DIR, 'death')) unless EMDirWatcher::PLATFORM == 'Windows'
    FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
    changed_paths = @tree.refresh!
    assert_equal "bar/foo", join(changed_paths)
  end

end

class TestTreeScopedRefresh < Test::Unit::TestCase

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

  unless EMDirWatcher::PLATFORM == 'Windows'
    should "fail with an exception when faced with an endless symlink loop" do
      assert_raises Errno::ELOOP do
        @tree = EMDirWatcher::Tree.new TEST_DIR
        FileUtils.ln_s(TEST_DIR, File.join(TEST_DIR, 'bar', 'death'))
        FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
        changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar')
      end
    end
  end

  should "report file deletion in inner directory when the scope specifies the directory" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.ln_s(TEST_DIR, File.join(TEST_DIR, 'death')) unless EMDirWatcher::PLATFORM == 'Windows'
    FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar')
    assert_equal "bar/foo", join(changed_paths)
  end

  should "report file deletion in inner directory when the scope specifies the file" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.ln_s(TEST_DIR, File.join(TEST_DIR, 'death')) unless EMDirWatcher::PLATFORM == 'Windows'
    FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar', 'foo')
    assert_equal "bar/foo", join(changed_paths)
  end

  should "not refresh the whole directory when the scope specifies a single file" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.ln_s(TEST_DIR, File.join(TEST_DIR, 'bar', 'death')) unless EMDirWatcher::PLATFORM == 'Windows'
    FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar', 'foo')
    assert_equal "bar/foo", join(changed_paths)
  end

  should "report file deletion in a subtree when the scope specifies a directory" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.ln_s(TEST_DIR, File.join(TEST_DIR, 'death')) unless EMDirWatcher::PLATFORM == 'Windows'
    FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'boo', 'bizzz')
    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar')
    assert_equal "bar/boo/bizzz", join(changed_paths)
  end

  should "report removed files when doing cascaded scoped refreshes" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.rm_rf File.join(TEST_DIR, 'bar')

    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar', 'boo')
    assert_equal "bar/boo/bizzz", join(changed_paths)

    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar')
    assert_equal "bar/biz, bar/biz.html, bar/foo", join(changed_paths)
  end

end

class TestTreeScopedNonRecursiveRefresh < Test::Unit::TestCase

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

  should "not report changes in a child directory" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'boo', 'bizzz')
    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar'), false
    assert_equal "", join(changed_paths)
  end

  should "report removed files" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar'), false
    assert_equal "bar/foo", join(changed_paths)
  end

  should "report added files" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.touch File.join(TEST_DIR, 'bar', 'coo')
    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar'), false
    assert_equal "bar/coo", join(changed_paths)
  end

  should "report entire subtree of a removed directory when the scope specifies that directory" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.rm_rf File.join(TEST_DIR, 'bar')
    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar'), false
    assert_equal "bar/biz, bar/biz.html, bar/boo/bizzz, bar/foo", join(changed_paths)
  end

  should "report entire subtree of an added directory when the scope specifies that directory" do
    FileUtils.mv File.join(TEST_DIR, 'bar'), ALT_TEST_DIR
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.mv File.join(ALT_TEST_DIR, 'bar'), TEST_DIR
    changed_paths = @tree.refresh! File.join(TEST_DIR, 'bar'), false
    assert_equal "bar/biz, bar/biz.html, bar/boo/bizzz, bar/foo", join(changed_paths)
  end

  should "report entire subtree of a removed directory when the scope specifies a parent directory" do
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.rm_rf File.join(TEST_DIR, 'bar')
    changed_paths = @tree.refresh! File.join(TEST_DIR), false
    assert_equal "bar/biz, bar/biz.html, bar/boo/bizzz, bar/foo", join(changed_paths)
  end

  should "report entire subtree of an added directory when the scope specifies a parent directory" do
    FileUtils.mv File.join(TEST_DIR, 'bar'), ALT_TEST_DIR
    @tree = EMDirWatcher::Tree.new TEST_DIR
    FileUtils.mv File.join(ALT_TEST_DIR, 'bar'), TEST_DIR
    changed_paths = @tree.refresh! File.join(TEST_DIR), false
    assert_equal "bar/biz, bar/biz.html, bar/boo/bizzz, bar/foo", join(changed_paths)
  end

end

unless EMDirWatcher::PLATFORM == 'Windows'
  class TestTreeSymlinkHandling < Test::Unit::TestCase

    def setup
      FileUtils.rm_rf TEST_DIR
      FileUtils.rm_rf ALT_TEST_DIR
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

      FileUtils.ln_s TEST_DIR, ALT_TEST_DIR

      @list = ['aa', 'biz', 'zz', 'bar/foo', 'bar/biz', 'bar/biz.html', 'bar/boo/bizzz'].sort
    end

    should "handle referencing root scope via symlink" do
      @tree = EMDirWatcher::Tree.new TEST_DIR
      FileUtils.rm_rf File.join(TEST_DIR, 'bar', 'foo')
      changed_paths = @tree.refresh! ALT_TEST_DIR
      assert_equal "bar/foo", join(changed_paths)
    end

    should "handle referencing root scope by real path when monitoring a symlinked path" do
      @tree = EMDirWatcher::Tree.new ALT_TEST_DIR
      FileUtils.rm_rf File.join(ALT_TEST_DIR, 'bar', 'foo')
      changed_paths = @tree.refresh! TEST_DIR
      assert_equal "bar/foo", join(changed_paths)
    end

  end
end
