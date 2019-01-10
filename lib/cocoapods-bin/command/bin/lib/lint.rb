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
              ['--template-podspec=A.binary-template.podspec', '生成拥有 subspec 的二进制 spec 需要的模版 podspec, 插件会更改 version 和 source'],
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
            @template_podspec = argv.option('template-podspec')
            super

            @additional_args = argv.remainder!
          end

          def run 
            Podfile.execute_with_use_binaries(!@code_dependencies) do 
              argvs = [
                "--sources=#{sources_option(@code_dependencies, @sources)}",
                *@additional_args
              ]

              argvs << spec_file if spec_file
              
              if @loose_options
                argvs << '--allow-warnings'
                argvs << '--use-libraries' if code_spec.all_dependencies.any?
              end
            
              lint = Pod::Command::Lib::Lint.new(CLAide::ARGV.new(argvs))
              lint.validate!
              lint.run
            end
          ensure
            clear_binary_spec_file_if_needed unless @reserve_created_spec
          end

          private


          def template_spec_file
            @template_spec_file ||= begin
              if @template_podspec
                find_spec_file(@template_podspec) 
              else 
                binary_template_spec_file
              end
            end
          end

          def spec_file
            @spec_file ||= begin
              if @podspec
                find_spec_file(@podspec) 
              else
                raise Informative, "当前目录下没有找到可用源码 podspec." if code_spec_files.empty?

                spec_file = if @binary
                              code_spec = Pod::Specification.from_file(code_spec_files.first)
                              template_spec = Pod::Specification.from_file(template_spec_file) if template_spec_file
                              create_binary_spec_file(code_spec, template_spec)
                            else
                              code_spec_files.first
                            end
                spec_file
              end
            end
          end
        end
      end
    end
  end
end
