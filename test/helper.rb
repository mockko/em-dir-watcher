require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'em-dir-watcher'

TEST_DIR = if EMDirWatcher::PLATFORM == 'Windows' then 'c:/tmp/emdwtest' else '/tmp/emdwtest' end # Dir.mktmpdir
ALT_TEST_DIR = TEST_DIR + 'alt' # Dir.mktmpdir

class Test::Unit::TestCase

    def join list
      list.join(", ").strip
    end

end
