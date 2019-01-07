require 'cocoapods-bin/config/config'
require 'cocoapods-bin/native'

module Pod
  class Command
    class Bin < Command
      class Lint < Bin 
        self.summary = 'lint 组件.'
        self.description = <<-DESC
          lint 二进制组件 / 源码组件, 默认使用 lib lint
        DESC

        self.arguments = [
          CLAide::Argument.new('NAME.podspec', false),
        ]

        def self.options
          [
            ['--spec', '使用 spec lint, 只支持本地，不支持链接'],
            ['--binary', 'lint 组件的二进制版本'],
            ['--code-dependency', '使用源码依赖进行 lint'],
            ['--loose-options', '添加宽松的 options'],
          ].concat(Pod::Command::Lib::Lint.options).concat(super).uniq
        end

        def initialize(argv)
          @spec = argv.flag?('spec')
          @podspec = argv.shift_argument
          @binary = argv.flag?('binary')
          @loose_options = argv.flag?('loose-options')
          @code_dependency = argv.flag?('code-dependency')
          @sources = argv.option('sources') || []
          super

          @additional_args = argv.remainder!
        end

        def run 
          Podfile.execute_with_use_binaries(!@code_dependency) do 
            argvs = [
              spec_file,
              "--sources=#{sources}",
              *@additional_args
            ]
            
            argvs += ['--allow-warnings', '--use-libraries'] if @loose_options

            lint_class = Object.const_get("Pod::Command::#{@spec ? 'Spec' : 'Lib'}::Lint") 
            lint = lint_class.new(CLAide::ARGV.new(argvs))
            lint.validate!
            lint.run
          end
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
          spec_generator = CBin::SpecGenerator.new(spec)
          spec_generator.generate
          spec_generator.write_to_file
          spec_generator.filename
        end

        def sources 
         (@sources + [binary_source, code_source].map(&:name)).join(',')
        end
      end
    end
  end
end
