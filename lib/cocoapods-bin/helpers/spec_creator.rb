require 'cocoapods'
require 'cocoapods-bin/config/config'

module CBin
  class Specification
    class Creator
      attr_reader :code_spec
      attr_reader :template_spec
      attr_reader :spec

      def initialize(code_spec, template_spec, platforms = 'ios') 
        @code_spec = code_spec
        @template_spec = template_spec
        @platforms = Array(platforms)
        validate!     
      end

      def validate!
        raise Pod::Informative, "源码 podspec 不能为空 ."  unless code_spec
        raise Pod::Informative, "不支持自动生成存在 subspec 的二进制 podspec , 需要提供模版文件 #{code_spec.name}.binary.podspec.template ."  if code_spec.subspecs.any? && template_spec.nil?
      end

      def create
        spec = template_spec ? create_from_code_spec_and_template_spec : create_from_code_spec

        Pod::UI.message "生成二进制 podspec 内容: "
        spec.to_pretty_json.split("\n").each do |text|
          Pod::UI.message text
        end

        spec
      end

      def write_spec_file(file = filename)
        create unless spec

        File.open(file, 'w+') do |f|
          f.write(spec.to_pretty_json)
        end

        @filename = file 
      end

      def clear_spec_file
        File.delete(filename) if File.exist?(filename)
      end

      def filename 
        @filename ||= "#{spec.name}.binary.podspec.json" 
      end

      private

      def create_from_code_spec
        @spec = code_spec.dup
        # vendored_frameworks | resources | source | source_files | public_header_files
        # license | resource_bundles | vendored_libraries

        # Project Linkin
        @spec.vendored_frameworks = "#{code_spec.root.name}.framework"

        # Resources
        extnames = []
        extnames << '*.bundle' if code_spec_consumer.resource_bundles.any?
        extnames += code_spec_consumer.resources.map { |r| File.basename(r) } if code_spec_consumer.resources.any?
        @spec.resources = framework_contents('Resources').flat_map { |r| extnames.map { |e| "#{r}/#{e}" } } if extnames.any?

        # Source Location
        @spec.source = binary_source

        # Source Code
        @spec.source_files = framework_contents('Headers/*')
        @spec.public_header_files = framework_contents('Headers/*')

        # Unused for binary 
        spec_hash = @spec.to_hash
        # spec_hash.delete('license')
        spec_hash.delete('resource_bundles')
        spec_hash.delete('exclude_files')
        spec_hash.delete('preserve_paths')
        # 这里不确定 vendored_libraries 指定的时动态/静态库
        # 如果是静态库的话，需要移除，否则就不移除
        # 最好是静态库都独立成 Pod ，cocoapods-package 打静态库去 collect 目标文件时好做过滤
        # 这里统一只对命名后缀 .a 文件做处理
        # spec_hash.delete('vendored_libraries')
        # libraries 只能假设为动态库不做处理了，如果有例外，需要开发者自行处理
        vendored_libraries = spec_hash.delete('vendored_libraries')
        vendored_libraries = Array(vendored_libraries).reject { |l| l.end_with?('.a') } 
        spec_hash['vendored_libraries'] = vendored_libraries if vendored_libraries.any?

        # Filter platforms
        platforms = spec_hash['platforms']
        selected_platforms = platforms.select { |k, v| @platforms.include?(k) } 
        spec_hash['platforms'] = selected_platforms.empty? ? platforms : selected_platforms
   
        @spec = Pod::Specification.from_hash(spec_hash)
        @spec
      end

      def create_from_code_spec_and_template_spec
        @spec = template_spec.dup

        @spec.version = code_spec.version
        @spec.source = binary_source
        @spec
      end

      def binary_source
        { http: CBin.config.binary_download_url % [code_spec.root.name, code_spec.version], type: CBin.config.download_file_type } 
      end

      def code_spec_consumer(platform = :ios)
        code_spec.consumer(:ios)
      end

      def framework_contents(name)
        ["#{code_spec.root.name}.framework", "#{code_spec.root.name}.framework/Versions/A"].map { |path| "#{path}/#{name}" }
      end
    end
  end
end