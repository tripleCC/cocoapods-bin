require 'cocoapods-bin/command/bin/repo/push'
require 'cocoapods-bin/command/bin/repo/update'

module Pod
  class Command
    class Bin < Command
      class Repo < Bin 
        self.abstract_command = true
        self.summary = '管理 spec 仓库.'
      end
    end
  end
end
