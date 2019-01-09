require 'cocoapods-bin/config/config'
require 'cocoapods-bin/native'

module Pod
  class Command
    class Bin < Command
      class Repo < Bin 
        class Push < Repo 
          self.summary = '发布组件.'
          self.description = <<-DESC
            发布二进制组件 / 源码组件
          DESC

          self.arguments = [
            CLAide::Argument.new('NAME.podspec', false),
          ]

          def self.options
            [
              ['--binary', '发布组件的二进制版本'],
              ['--code-dependencies', '使用源码依赖进行 lint'],
              ['--loose-options', '添加宽松的 options'],
              ['--reserve-created-spec', '保留生成的二进制 spec 文件'],
            ].concat(Pod::Command::Repo::Push.options).concat(super).uniq
          end

          def initialize(argv)
            @podspec = argv.shift_argument
            @binary = argv.flag?('binary')
            @loose_options = argv.flag?('loose-options')
            @code_dependencies = argv.flag?('code-dependencies')
            @sources = argv.option('sources') || []
            @reserve_created_spec = argv.flag?('reserve-created-spec')
            super

            @additional_args = argv.remainder!
          end

          def run 
            Podfile.execute_with_use_binaries(!@code_dependencies) do 
              argvs = [
                repo,
                spec_file,
                "--sources=#{sources_option(@code_dependencies, @sources)}",
                *@additional_args
              ]

              argvs += ['--allow-warnings', '--use-libraries', '--use-json'] if @loose_options
            
              push = Pod::Command::Repo::Push.new(CLAide::ARGV.new(argvs))
              push.validate!
              push.run
            end
          ensure
            @spec_generator.clear_spec_file if @spec_generator && !@reserve_created_spec
          end

          private

          def spec_file
            if @podspec
              path = Pathname(@podspec)
              raise Informative, "Couldn't find #{@podspec}" unless path.exist?
              path
            else
              raise Informative, "Couldn't find any podspec files in current directory" if spec_files.empty?
              raise Informative, "Couldn't find any code podspec files in current directory" if code_spec_files.empty? && !@binary
              path = code_spec_files.first
              path = binary_spec_files.first || generate_binary_spec_file(path) if @binary
              path
            end
          end

          def generate_binary_spec_file(code_spec_path)
            spec = Pod::Specification.from_file(code_spec_path)
            @spec_generator = CBin::SpecGenerator.new(spec)
            @spec_generator.generate
            @spec_generator.write_to_spec_file
            @spec_generator.filename
          end

          def repo
            @binary ? binary_source.name : code_source.name 
          end
        end
      end
    end
  end
end
