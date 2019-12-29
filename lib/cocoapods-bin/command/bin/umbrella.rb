# frozen_string_literal: true

module Pod
  class Command
    class Bin < Command
      class Umbrella < Bin
        self.summary = '生成伞头文件 .'

        self.arguments = [
          CLAide::Argument.new('PATH', false)
        ]

        def initialize(argv)
          @path = Pathname.new(argv.shift_argument || '.')
          @spec_file = code_spec_files.first
          super
        end

        def validate!
          super
          if @spec_file.nil?
            help! '[!] No `Podspec` found in the project directory.'
          end
        end

        def run
          pod_name = @spec_file.to_s.split('.').first

          @path += "#{pod_name}.h" if @path.directory?

          UI.puts "Generateing umbrella file for #{pod_name}"

          header_generator = Pod::Generator::Header.new(Platform.ios)
          spec = Pod::Specification.from_file(Pathname.new(@spec_file))
          public_header_files = spec.consumer(:ios).public_header_files
          if public_header_files.empty?
            public_header_files = spec.consumer(:ios).source_files
          end
          public_header_files = Pathname.glob(public_header_files).map(&:basename).select do |pathname|
            pathname.extname.to_s == '.h' &&
              pathname.basename('.h').to_s != pod_name
          end

          header_generator.imports = public_header_files

          UI.puts "Save umbrella file to #{@path.expand_path}"

          header_generator.save_as(@path)

          UI.puts 'Done!'.green
        end
      end
    end
  end
end
