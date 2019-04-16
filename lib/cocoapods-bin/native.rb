require 'cocoapods'

if Pod.match_version?('~> 1.4')
	require 'cocoapods-bin/native/podfile'
	require 'cocoapods-bin/native/installation_options'
	require 'cocoapods-bin/native/specification'
	require 'cocoapods-bin/native/path_source'
	require 'cocoapods-bin/native/analyzer'
	require 'cocoapods-bin/native/installer'
	require 'cocoapods-bin/native/pod_source_installer'
	require 'cocoapods-bin/native/linter'
	require 'cocoapods-bin/native/resolver'
	require 'cocoapods-bin/native/source'
	require 'cocoapods-bin/native/validator'
	require 'cocoapods-bin/native/acknowledgements'
	require 'cocoapods-bin/native/sandbox_analyzer'
	require 'cocoapods-bin/native/podspec_finder'
end
