
module Pod
  class Specification
    class Linter
    	# !@group Lint steps

      # Checks that the spec's root name matches the filename.
      #
      # @return [void]
      #
      def validate_root_name
        if spec.root.name && file
          acceptable_names = [
            spec.root.name + '.podspec',
            spec.root.name + '.podspec.json',
            # 支持 binary 后缀
            spec.root.name + '.binary.podspec',
            spec.root.name + '.binary.podspec.json'
          ]
          names_match = acceptable_names.include?(file.basename.to_s)
          unless names_match
            results.add_error('name', 'The name of the spec should match the ' \
                              'name of the file.')
          end
        end
      end
    end
  end
end