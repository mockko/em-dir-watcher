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

end
