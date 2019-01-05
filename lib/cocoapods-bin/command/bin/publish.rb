require 'cocoapods-bin/config/config'

module Pod
  class Command
    class Bin < Command
      class Init < Bin 
        self.summary = '发布组件.'
        self.description = <<-DESC
          发布二进制组件 / 源码组件
        DESC

        self.arguments = [
          CLAide::Argument.new('NAME.podspec', false),
        ]

        def self.options
          [
            ['--binary', '推送二进制组件'],
            ['--lint-use-code', '使用源码依赖进行 lint'],
            ['--sources=https://github.com/artsy/Specs,master', 'The sources from which to pull dependent pods ' \
             '(defaults to all available repos). ' \
             'Multiple sources must be comma-delimited.'],
            ['--commit-message="Fix bug in pod"', 'Add custom commit message. ' \
            'Opens default editor if no commit message is specified.'],
          ].concat(super)
        end

        def initialize(argv)
          @podspec = argv.shift_argument
          @binary = argv.flag?('binary')
          @lint_use_code = argv.flag?('lint-use-code')
          @sources = Array(argv.option('sources'))
          @message = argv.option('commit-message')
          super
        end

        def run 
          argvs = [
              default_source.name,
              @spec_file,
              "--sources=#{@sources + code_binary_source_names}",
              '--allow-warnings',
              '--use-libraries',
          ]
          argvs << %Q[--commit-message=#{commit_prefix(spec) + "\n" + @commit_message}] unless @commit_message.to_s.empty?

          push = Pod::Command::Repo::Push.new(CLAide::ARGV.new(argvs))
          push.validate!
          push.run

          raise StandardError, "执行 pod repo push 失败，错误信息 #{$?}".red if $?.exitstatus != 0
        end

        private

        def podspec_file
          if @podspec
            path = Pathname(@podspec)
            raise Informative, "Couldn't find #{@podspec}" unless path.exist?
            path
          else
            files = Pathname.glob('*.podspec{,.json}')
            raise Informative, "Couldn't find any podspec files in current directory" if files.empty?
            path = files.first

            if @binary
              binary_files = Pathname.glob('*.binary.podspec{,.json}')
              if binary_files.empty?
                spec = Pod::Specification.from_file(path)
                factory = CBin::SpecGenerator.new(spec)
                bspec = factory.generate
                # 根据源码 podspec 生成二进制 podspec
                path = binary_files.first 
              else
                path = binary_files.first 
              end
            end

            path
          end
        end

        def code_binary_source_names
          [sources_manager.binary_source.name, sources_manager.code_source.name]
        end

        def sources_manager
          sources_manager = Config.instance.sources_manager
        end

        def default_source
          @binary ? sources_manager.binary_source : sources_manager.code_source
        end

        def commit_prefix(spec)
          output_path = default_source.pod_path(spec.name) + spec.version.to_s
          if output_path.exist?
            message = "[Fix] #{spec}"
          elsif output_path.dirname.directory?
            message = "[Update] #{spec}"
          else
            message = "[Add] #{spec}"
          end
        end
      end
    end
  end
end
