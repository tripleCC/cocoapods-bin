module Pod
  class Command
    class Bin < Command
      class Open < Bin 
        self.summary = '打开 workspace 工程.'

        def self.options
          [
            ['--install', '先执行 install, 再执行 open. 相当于 pod install && pod bin open'],
            ['--update', '先执行 update, 再执行 open. 相当于 pod update && pod bin open'],
            ['--deep=5', '查找深度.'],
          ]
        end

        def initialize(argv)
          @install = argv.flag?('install')
          @update = argv.flag?('update')
          @deep = argv.option('deep').try(:to_i) || 3
          super
        end

        def run
          if @install || @update
            command_class = Object.const_get("Pod::Command::#{@install ? 'Install' : 'Update'}")
            command = command_class.new(CLAide::ARGV.new([])) 
            command.validate!
            command.run
          end

          path = find_in_children(Pathname.pwd.children, @deep) || 
            find_in_parent(Pathname.pwd.parent, @deep)
          if path
            `open #{path}` 
          else 
            UI.puts "#{Pathname.pwd} 目录, 搜索上下深度 #{@deep} , 无法找到 xcworkspace 文件.".red
          end
        end

        def find_in_children(paths, deep)
          deep -= 1
          pathname = paths.find { |ph| ph.extname == '.xcworkspace' }

          return pathname if pathname || paths.empty? || deep <= 0

          find_in_children(paths.select(&:directory?).flat_map(&:children), deep)
        end

        def find_in_parent(path, deep)
          deep -= 1
          pathname = path.children.find {|fn| fn.extname == '.xcworkspace'}

          return pathname if pathname || deep <= 0

          find_in_parent(path.parent, deep)
        end
      end
    end
  end
end
