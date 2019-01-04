require 'cocoapods-bin/helpers/spec_generator'

module Pod
  class Command
    class Bin < Command
      class CSpec < Bin 
        self.summary = '创建二进制 spec.'
        self.description = <<-DESC
          根据源码 spec，创建对应的二进制 spec.
        DESC

        self.arguments = [
          CLAide::Argument.new('NAME.podspec', false),
        ]

        def initialize(argv)
          @podspec = argv.shift_argument
          super
        end

        def run 
          UI.puts "开始读取 #{podspec_file} 文件...\n"
          spec = Pod::Specification.from_file(podspec_file)

          UI.puts "开始生成二进制 podspec 文件...\n"
          spec_generator = CBin::SpecGenerator.new(spec)
          spec_generator.generate

          file_name = "#{spec.name}.binary.podspec.json"
          UI.puts "开始保存 #{file_name} 文件至当前目录...\n"
          File.open(file_name, 'w+') do |f|
            f.write(spec_generator.spec.to_pretty_json)
          end
          UI.puts "创建二进制 podspec 文件成功.\n".green
        end

        private 

        def podspec_file
          @podspec_file ||= begin
            if @podspec
              path = Pathname(@podspec)
              raise Informative, "Couldn't find #{@podspec}" unless path.exist?
              path
            else
              files = Pathname.glob('*.podspec{,.json}') - Pathname.glob('*binary.podspec{,.json}')
              raise Informative, "Couldn't find any valid podspec files in current directory" if files.empty?
              files.first
            end
          end
        end
      end
    end
  end
end
