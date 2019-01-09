require 'cocoapods'
require 'cocoapods-bin/config/config'

module CBin
	class SpecGenerator
		attr_reader :ref_spec
		attr_reader :spec

		def initialize(ref_spec, platforms = 'ios') 
			@ref_spec = ref_spec
			@platforms = Array(platforms)
			validate!			
		end

		def validate!
			raise StandardError, '不支持自动生成存在 subspec 的二进制 podspec .' if ref_spec.subspecs.any?
		end

		def generate 
			@spec = @ref_spec.dup
			# vendored_frameworks | resources | source | source_files | public_header_files
			# license | resource_bundles

			# Project Linkin
			@spec.vendored_frameworks = "#{ref_spec.root.name}.framework"

			# Resources
			extnames = []
			extnames << '*.bundle' if ref_spec_consumer.resource_bundles.any?
			extnames += ref_spec_consumer.resources.map { |r| File.basename(r) } if ref_spec_consumer.resources.any?
			@spec.resources = framework_contents('Resources').flat_map { |r| extnames.map { |e| "#{r}/#{e}" } } if extnames.any?

			# Source Location
			@spec.source = { http: CBin.config.binary_download_url % [ref_spec.root.name, ref_spec.version] }

			# Source Code
			@spec.source_files = framework_contents('Headers/*')
			@spec.public_header_files = framework_contents('Headers/*')

			# Unused for binary 
			spec_hash = @spec.to_hash
			spec_hash.delete('license')
			spec_hash.delete('resource_bundles')

			# Filter platforms
			platforms = spec_hash['platforms']
			selected_platforms = platforms.select { |k, v| @platforms.include?(k) } 
			spec_hash['platforms'] = selected_platforms.empty? ? platforms : selected_platforms
 
			@spec = Pod::Specification.from_hash(spec_hash)

			Pod::UI.message "生成二进制 podspec 内容: "
      @spec.to_pretty_json.split("\n").each do |text|
        Pod::UI.message text
      end

			@spec
		end

		def write_to_spec_file(file = filename)
			File.open(file, 'w+') do |f|
        f.write(spec.to_pretty_json)
      end

      @filename = file 
		end

		def clear_spec_file
			File.delete(@filename) if File.exist?(@filename)
		end

		def filename 
			@filename ||= "#{spec.name}.binary.podspec.json" 
		end

		private

		def ref_spec_consumer(platform = :ios)
			ref_spec.consumer(:ios)
		end

		def framework_contents(name)
			["#{ref_spec.root.name}.framework", "#{ref_spec.root.name}.framework/Versions/A"].map { |path| "#{path}/#{name}" }
		end
	end
end