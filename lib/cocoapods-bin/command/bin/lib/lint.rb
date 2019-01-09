require 'cocoapods-bin/config/config'
require 'cocoapods-bin/native'

module Pod
  class Command
    class Bin < Command
      class Lib < Bin 
        class Lint < Lib
          self.summary = 'lint 组件.'
          self.description = <<-DESC
            lint 二进制组件 / 源码组件
          DESC

          self.arguments = [
            CLAide::Argument.new('NAME.podspec', false),
          ]

          def self.options
            [
              ['--binary', 'lint 组件的二进制版本'],
              ['--code-dependencies', '使用源码依赖进行 lint'],
              ['--loose-options', '添加宽松的 options, 可能包括 --use-libraries (可能会造成 entry point (start) undefined)'],
              ['--reserve-created-spec', '保留生成的二进制 spec 文件'],
            ].concat(Pod::Command::Lib::Lint.options).concat(super).uniq
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
                spec_file,
                "--sources=#{sources_option(@code_dependencies, @sources)}",
                *@additional_args
              ]
              
              if @loose_options
                argvs << '--allow-warnings'
                argvs << '--use-libraries' if spec.all_dependencies.any?
              end
            

              lint = Pod::Command::Lib::Lint.new(CLAide::ARGV.new(argvs))
              lint.validate!
              lint.run
            end
          ensure
            @spec_generator.clear_spec_file if @spec_generator && !@reserve_created_spec
          end

          private

          def spec 
            Pod::Specification.from_file(spec_file)
          end

          def spec_file
            @spec_file ||= begin
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
          end

          def generate_binary_spec_file(code_spec_path)
            spec = Pod::Specification.from_file(code_spec_path)
            @spec_generator = CBin::SpecGenerator.new(spec)
            @spec_generator.generate
            @spec_generator.write_to_spec_file
            @spec_generator.filename
          end
        end
      end
    end
  end
end
