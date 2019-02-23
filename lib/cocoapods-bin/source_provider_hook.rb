require 'cocoapods-bin/native/sources_manager'

Pod::HooksManager.register('cocoapods-bin', :pre_install) do |context, _|
	require 'cocoapods-bin/native'
end

Pod::HooksManager.register('cocoapods-bin', :source_provider) do |context, _|
  sources_manager = Pod::Config.instance.sources_manager
  podfile = Pod::Config.instance.podfile

  if podfile
	  # 添加二进制私有源 && 源码私有源
	  added_sources = [sources_manager.code_source, sources_manager.binary_source]
	  added_sources.reverse! if podfile.use_binaries? || podfile.use_binaries_selector
	  added_sources.each { |source| context.add_source(source) }
	end
end