if Pod.match_version?('~> 1.4')
	require 'cocoapods-bin/native/analyzer'
	require 'cocoapods-bin/native/installer'
	require 'cocoapods-bin/native/pod_source_installer'
	require 'cocoapods-bin/native/linter'
	require 'cocoapods-bin/native/resolver'
	require 'cocoapods-bin/native/source'
end

require 'cocoapods-bin/native/source_provider_hook'
