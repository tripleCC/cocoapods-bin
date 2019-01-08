require 'cocoapods-bin/config/config'
require 'cocoapods-bin/native'

module Pod
  class Command
    class Bin < Command
      class Spec < Bin 
        class Lint < Spec
          self.summary = 'lint spec.'
          self.description = <<-DESC
            spec lint 二进制组件 / 源码组件
          DESC

          self.arguments = [
            CLAide::Argument.new(%w(NAME.podspec DIRECTORY http://PATH/NAME.podspec), false, true)
          ]

          def self.options
            [
              ['--code-dependency', '使用源码依赖进行 lint'],
              ['--loose-options', '添加宽松的 options'],
            ].concat(Pod::Command::Lib::Spec.options).concat(super).uniq
          end

          def initialize(argv)
            @loose_options = argv.flag?('loose-options')
            @code_dependency = argv.flag?('code-dependency')
            @sources = argv.option('sources') || []
            super

            @additional_args = argv.remainder!
          end

          def run 
            Podfile.execute_with_use_binaries(!@code_dependency) do 
              argvs = [
                "--sources=#{sources}",
                *@additional_args
              ]
              
              argvs += ['--allow-warnings', '--use-libraries'] if @loose_options

              lint = Pod::Command::Spec::Lint.new(CLAide::ARGV.new(argvs))
              lint.validate!
              lint.run
            end
          end

          private

          def sources 
           (@sources + [binary_source, code_source].map(&:name)).join(',')
          end
        end
      end
    end
  end
end
