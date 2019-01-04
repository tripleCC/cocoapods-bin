if Pod.match_version?('>= 1.2') #, '<= 1.6.1')
	require 'cocoapods-bin/native/analyzer'
	require 'cocoapods-bin/native/installer'
	require 'cocoapods-bin/native/pod_source_installer'
	require 'cocoapods-bin/native/resolver'
end

require 'cocoapods-bin/native/source_provider_hook'
