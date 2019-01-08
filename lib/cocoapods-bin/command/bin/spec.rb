require 'cocoapods-bin/command/bin/spec/create'
require 'cocoapods-bin/command/bin/spec/lint'

module Pod
  class Command
    class Bin < Command
      class Spec < Bin 
        self.abstract_command = true
        self.summary = '管理二进制 spec.'
      end
    end
  end
end
