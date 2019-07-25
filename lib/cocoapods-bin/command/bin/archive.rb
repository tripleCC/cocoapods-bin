require 'cocoapods-bin/native/podfile'
require 'cocoapods/command/gen'
require 'cocoapods/generate'
require 'cocoapods-bin/helpers/framework_builder'

module Pod
  class Command
    class Bin < Command
      class Archive < Bin 
        self.summary = '将组件归档为静态 framework.'
        self.description = <<-DESC
          将组件归档为静态 framework，仅支持 iOS 平台
          此静态 framework 不包含依赖组件的 symbol
        DESC

        def self.options
          [
            ['--code-dependencies', '使用源码依赖'],
            ['--allow-prerelease', '允许使用 prerelease 的版本'],
            ['--use-modular-headers', '使用 modular headers (modulemap)'],
            ['--no-clean', '保留构建中间产物'],
            ['--no-zip', '不压缩静态 framework 为 zip'],
            ].concat(super)
        end

        self.arguments = [
          CLAide::Argument.new('NAME.podspec', false),
        ]

        def initialize(argv)
          @code_dependencies = argv.flag?('code-dependencies')
          @allow_prerelease = argv.flag?('allow-prerelease')
          @clean = argv.flag?('clean', true)
          @zip = argv.flag?('zip', true)
          @use_modular_headers = argv.flag?('use-modular-headers')
          @platform = Platform.new(:ios)
          super

          @additional_args = argv.remainder!
        end

        def run 
          @spec = Specification.from_file(spec_file)
          generate_project
          build_static_framework
          zip_static_framework if @zip
          clean_workspace if @clean
        end

        private

        def generate_project
          Podfile.execute_with_bin_plugin do
            Podfile.execute_with_allow_prerelease(@allow_prerelease) do 
              Podfile.execute_with_use_binaries(!@code_dependencies) do 
                argvs = [
                  "--sources=#{sources_option(@code_dependencies, @sources)}",
                  "--gen-directory=#{gen_name}",
                  '--clean',
                  '--use-libraries',
                  *@additional_args
                ]

                argvs << '--use-modular-headers' if @use_modular_headers
                argvs << spec_file if spec_file
              
                gen = Pod::Command::Gen.new(CLAide::ARGV.new(argvs))
                gen.validate!
                gen.run
              end
            end
          end
        end

        def zip_static_framework
          output_name = "#{framework_name}.zip"
          raise Informative, "没有需要压缩的 framework 文件：#{framework_name}" unless File.exist?(framework_name)

          UI.puts "Compressing #{framework_name} into #{output_name}"

          `zip --symlinks -r #{output_name} #{framework_name}`
        end

        def build_static_framework
          source_dir = Dir.pwd
          file_accessor = Sandbox::FileAccessor.new(Pathname.new(".").expand_path, @spec.consumer(@platform))
          Dir.chdir(workspace_directory) do 
            builder = CBin::Framework::Builder.new(@spec, file_accessor, @platform, source_dir)
            builder.build
          end
        end

        def clean_workspace
          UI.puts "Cleaning workspace"

          FileUtils.rm_rf(gen_name)
          FileUtils.rm_rf(framework_name) if @zip 
        end

        def gen_name
          "bin-archive"
        end

        def framework_name
          "#{@spec.name}.framework"
        end

        def workspace_directory
          File.expand_path("./#{gen_name}/#{@spec.name}")
        end

        def spec_file
          @spec_file ||= begin
            if @podspec
              find_spec_file(@podspec) 
            else
              raise Informative, "当前目录下没有找到可用源码 podspec." if code_spec_files.empty?

              spec_file = code_spec_files.first
              spec_file
            end
          end
        end
      end
    end
  end
end
