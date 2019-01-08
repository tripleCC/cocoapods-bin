require 'cocoapods-bin/native'

module CBin
	module SpecFilesHelper
    def spec_files
      @spec_files ||= Pathname.glob('*.podspec{,.json}')
    end

    def binary_spec_files
      @binary_spec_files ||= Pathname.glob('*.binary.podspec{,.json}')
    end

    def code_spec_files
      @code_spec_files ||= spec_files - binary_spec_files
    end
	end
end