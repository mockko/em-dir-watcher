
require 'win32/api'

module EMDirWatcher
module Platform
module Windows

private

  GetModuleFileName = Win32::API.new('GetModuleFileName', 'LPL', 'L', 'kernel32')

public

  def self.path_to_ruby_exe
    buf = 0.chr * 260
    GetModuleFileName.call(0, buf, buf.length)
    buf.strip 
  end

end
end
end
