require 'cocoapods-bin/config/config'
require 'cocoapods-bin/native'

module Pod
  class Command
    class Bin < Command
      class Publish < Bin 
        self.summary = '发布组件.'
        self.description = <<-DESC
          发布二进制组件 / 源码组件
        DESC

        self.arguments = [
          CLAide::Argument.new('NAME.podspec', false),
        ]

        def self.options
          [
            ['--binary', '发布二进制组件'],
            ['--lint-use-code', '使用源码依赖进行 lint'],
          ].concat(Pod::Command::Repo::Push.options).concat(super).uniq
        end

        def initialize(argv)
          @podspec = argv.shift_argument
          @binary = argv.flag?('binary')
          @lint_use_code = argv.flag?('lint-use-code')
          @sources = argv.option('sources') || []
          super

          @additional_args = argv.remainder!
        end

        def run 
          Podfile.execute_with_use_binaries(!@lint_use_code) do 
            argvs = [
              repo,
              spec_file,
              "--sources=#{sources}",
              *@additional_args
            ]
            
            begin 
              push = Pod::Command::Repo::Push.new(CLAide::ARGV.new(argvs))
              push.validate!
              push.run
            rescue => error 
              raise StandardError, "执行 pod repo push 失败，错误信息 #{error}".red
            end
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
          # 根据源码 podspec 生成二进制 podspec
          spec_generator.filename
        end

        def sources 
         (@sources + [binary_source, code_source].map(&:name)).join(',')
        end

        def repo
          @binary ? binary_source.name : code_source.name 
        end
      end
    end
  end
end
