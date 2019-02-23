module Pod
  class Podfile
    USE_BINARIES = 'use_binaries'.freeze
    USE_SOURCE_PODS = 'use_source_pods'.freeze
    USE_BINARIES_SELECTOR = 'use_binaries_selector'.freeze
    ALLOW_PRERELEASE = 'allow_prerelease'.freeze
    USE_PLUGINS = 'use_plugins'.freeze

    module ENVExecutor
      def execute_with_bin_plugin(&block)
        execute_with_key(USE_PLUGINS, -> {'cocoapods-bin'}, &block)
      end

      def execute_with_allow_prerelease(allow_prerelease, &block)
        execute_with_key(ALLOW_PRERELEASE, -> { allow_prerelease ? 'true' : 'false' }, &block)
      end
      
      def execute_with_use_binaries(use_binaries, &block)
        execute_with_key(USE_BINARIES, -> { use_binaries ? 'true' : 'false' }, &block)
      end

      def execute_with_key(key, value_returner, &block)
        origin_value = ENV[key]
        ENV[key] = value_returner.call

        yield if block_given?

        ENV[key] = origin_value
      end
    end

    extend ENVExecutor
  end
end