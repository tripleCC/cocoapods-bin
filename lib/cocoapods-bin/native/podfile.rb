require 'cocoapods'

module Pod
  class Podfile
    USE_BINARIES = 'use_binaries'.freeze
    USE_SOURCE_PODS = 'use_source_pods'.freeze
    USE_BINARIES_SELECTOR = 'use_binaries_selector'.freeze
    ALLOW_PRERELEASE = 'allow_prerelease'.freeze
    # TREAT_DEVELOPMENTS_AS_NORMAL = 'treat_developments_as_normal'.freeze

    module DSL
      def allow_prerelease!
        set_internal_hash_value(ALLOW_PRERELEASE, true)
      end

      def use_binaries!(flag = true)
        set_internal_hash_value(USE_BINARIES, flag)
      end

      def use_binaries_with_spec_selector!(&block)
        raise Informative, '必须提供选择需要二进制组件的 block !' unless block_given?

        set_internal_hash_value(USE_BINARIES_SELECTOR, block)
      end

      def set_use_source_pods(pods)
        hash_pods_use_source = get_internal_hash_value(USE_SOURCE_PODS) || []
        hash_pods_use_source += Array(pods)
        set_internal_hash_value(USE_SOURCE_PODS, hash_pods_use_source)
      end
    end

    module ENVExecutor
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

    def use_binaries_selector
      get_internal_hash_value(USE_BINARIES_SELECTOR, nil)
    end

    def allow_prerelease?
      get_internal_hash_value(ALLOW_PRERELEASE, false) || ENV[ALLOW_PRERELEASE] == 'true'
    end

    def use_binaries?
      get_internal_hash_value(USE_BINARIES, false) || ENV[USE_BINARIES] == 'true'
    end

    def use_source_pods
      get_internal_hash_value(USE_SOURCE_PODS, []) + String(ENV[USE_SOURCE_PODS]).split('|').uniq
    end

    private
    # set_hash_value 有 key 限制
    def set_internal_hash_value(key, value)
      internal_hash[key] = value
    end

    def get_internal_hash_value(key, default = nil)
      internal_hash.fetch(key, default)
    end
  end
end