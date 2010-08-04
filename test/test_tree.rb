require 'helper'
require 'fileutils'
require 'eventmachine'

TEST_DIR = '/tmp/emdwtest' # Dir.mktmpdir

class TestTreeFileList < Test::Unit::TestCase
  
  def setup
    FileUtils.rm_rf TEST_DIR
    FileUtils.mkdir_p TEST_DIR
    @tree = EMDirWatcher::Tree.new TEST_DIR
  end

  should "should be empty for an empty directory" do
    assert_equal "", @tree.full_file_list.join(", ").strip
  end

  should "should return a single file" do
    FileUtils.touch File.join(TEST_DIR, 'foo')
    assert_equal "foo", @tree.full_file_list.join(", ").strip
  end

  should "should return a file in a subdirectory" do
    FileUtils.mkdir File.join(TEST_DIR, 'bar')
    FileUtils.touch File.join(TEST_DIR, 'bar', 'foo')
    assert_equal "bar/foo", @tree.full_file_list.join(", ").strip
  end

  should "should return a sorted list of files" do
    FileUtils.touch File.join(TEST_DIR, 'aa')
    FileUtils.touch File.join(TEST_DIR, 'zz')
    FileUtils.mkdir File.join(TEST_DIR, 'bar')
    FileUtils.touch File.join(TEST_DIR, 'bar', 'foo')
    assert_equal "aa, bar/foo, zz", @tree.full_file_list.join(", ").strip
  end

end

class TestTreeExcludes < Test::Unit::TestCase

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

    @tree = EMDirWatcher::Tree.new TEST_DIR
  end

  def join list
    list.join(", ").strip
  end

  should "ignore a single file excluded by path" do
    @tree.excludes = ['bar/biz']
    assert_equal join(@list - ['bar/biz']), join(@tree.full_file_list)
  end

  should "ignore files excluded by name" do
    @tree.excludes = ['biz']
    assert_equal join(@list - ['biz', 'bar/biz']), join(@tree.full_file_list)
  end

  should "ignore files excluded by name glob" do
    @tree.excludes = ['biz*']
    assert_equal join(@list - ['biz', 'bar/biz', 'bar/biz.html', 'bar/boo/bizzz']), join(@tree.full_file_list)
  end

  should "ignore a directory excluded by name glob" do
    @tree.excludes = ['bo*']
    assert_equal join(@list - ['bar/boo/bizzz']), join(@tree.full_file_list)
  end

  should "ignore a files and directories excluded by regexp" do
    @tree.excludes = [/b/]
    assert_equal join(['aa', 'zz']), join(@tree.full_file_list)
  end

end
