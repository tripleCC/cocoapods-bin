require 'cocoapods-bin/command/bin/init'
require 'cocoapods-bin/command/bin/cspec'
require 'cocoapods-bin/command/bin/lint'
require 'cocoapods-bin/command/bin/publish'


module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Bin < Command
      self.abstract_command = true
      self.summary = '组件二进制化插件.'
      self.description = <<-DESC
        利用源码私有源与二进制私有源，实现的组件二进制化插件。
        可通过在 Podfile 中设置 use_binaries! ，指定所有组件使用二进制依赖，
        设置 set_use_source_pods ，指定需要使用源码依赖的组件
      DESC

      def initialize(argv)
        @help = argv.flag?('help')
        super 
      end

      def validate!
        super
        # 这里由于 --help 是在 validate! 方法中提取的，会导致 --help 失效
        # pod lib create 也有这个问题
        banner! if @help
      end

      def sources_manager
        Config.instance.sources_manager
      end

      def binary_source
        sources_manager.binary_source
      end

      def code_source
        sources_manager.code_source
      end

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
end
