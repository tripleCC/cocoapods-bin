# frozen_string_literal: true

require 'cocoapods-bin/native/sources_manager'

Pod::HooksManager.register('cocoapods-bin', :pre_install) do |_context, _|
  require 'cocoapods-bin/native'

  # 同步 BinPodfile 文件
  project_root = Pod::Config.instance.project_root
  path = File.join(project_root.to_s, 'BinPodfile')

  return unless File.exist?(path)

  contents = File.open(path, 'r:utf-8', &:read)

  podfile = Pod::Config.instance.podfile
  podfile.instance_eval do
    # rubocop:disable Lint/RescueException
    begin
      # rubocop:disable Eval
      eval(contents, nil, path)
      # rubocop:enable Eval
    rescue Exception => e
      message = "Invalid `#{path}` file: #{e.message}"
      raise Pod::DSLError.new(message, path, e, contents)
    end
    # rubocop:disable Lint/RescueException
  end
end

Pod::HooksManager.register('cocoapods-bin', :source_provider) do |context, _|
  sources_manager = Pod::Config.instance.sources_manager
  podfile = Pod::Config.instance.podfile

  if podfile
    # 添加二进制私有源 && 源码私有源
    added_sources = [sources_manager.code_source, sources_manager.binary_source]
    if podfile.use_binaries? || podfile.use_binaries_selector
      added_sources.reverse!
   end
    added_sources.each { |source| context.add_source(source) }
  end
end
