require 'cocoapods-bin/gem_version.rb'
require 'cocoapods-bin/command'

if CocoapodsBin.match_version?('>= 1.2') #, '<= 1.6.1')
	require 'cocoapods-bin/analyzer'
	require 'cocoapods-bin/installer'
	require 'cocoapods-bin/pod_source_installer'
	require 'cocoapods-bin/resolver'
end

require 'cocoapods-bin/source_provider_hook'
