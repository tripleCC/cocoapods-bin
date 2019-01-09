require 'cocoapods-bin/helpers/spec_generator'

module Pod
  class Command
    class Bin < Command
      class Spec < Bin 
        class Create < Spec
          self.summary = '创建二进制 spec.'
          self.description = <<-DESC
            根据源码 podspec 文件，创建对应的二进制 podspec 文件.
          DESC

          self.arguments = [
            CLAide::Argument.new('NAME.podspec', false),
          ]

          def self.options
            [
              ['--platforms=ios', '生成二进制 spec 支持的平台'],
              ['--no-overwrite', '不允许覆盖']
            ].concat(super)
          end

          def initialize(argv)
            @platforms = argv.option('platforms') || 'ios'
            @allow_overwrite = argv.flag?('overwrite', true)
            @podspec = argv.shift_argument
            super
          end

          def run 

            UI.puts "开始读取 #{podspec_file} 文件...\n"
            spec = Pod::Specification.from_file(podspec_file)

            UI.puts "开始生成二进制 podspec 文件...\n"
            spec_generator = CBin::SpecGenerator.new(spec, @platforms)
            spec_generator.generate

            UI.puts "开始保存 #{spec_generator.filename} 文件至当前目录...\n"

            if File.exist?(spec_generator.filename) && !@allow_overwrite
              UI.warn "二进制 podspec 文件 #{spec_generator.filename} 已存在.\n"
            else
              spec_generator.write_to_spec_file
              UI.puts "创建二进制 podspec 文件成功.\n".green
            end
          end

          private 

          def podspec_file
            @podspec_file ||= begin
              if @podspec
                path = Pathname(@podspec)
                raise Informative, "Couldn't find #{@podspec}" unless path.exist?
                path
              else
                raise Informative, "Couldn't find any valid podspec files in current directory" if code_spec_files.empty?
                code_spec_files.first
              end
            end
          end
        end
      end
    end
  end
end
