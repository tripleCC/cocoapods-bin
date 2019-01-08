require 'cocoapods-bin/command/bin/lib/lint'

module Pod
  class Command
    class Bin < Command
      class Lib < Bin 
        self.abstract_command = true
        self.summary = '管理二进制 pod.'
      end
    end
  end
end
