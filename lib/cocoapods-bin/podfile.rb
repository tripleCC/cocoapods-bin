module Pod
	class Podfile
		module DSL
			def use_binaries!(flag = true)
				set_internal_hash_value('use_binaries', flag)
			end

			def use_binaries_with_spec_selector!(&block)
				raise Informative, '必须提供选择需要二进制组件的 block !' unless block_given?

				set_internal_hash_value('use_binaries_selector', block)
			end

			def set_use_source_pods(pods)
				hash_pods_use_source = get_internal_hash_value('use_source_pods') || []
				hash_pods_use_source += Array(pods)
				set_internal_hash_value('use_source_pods', hash_pods_use_source)
			end
		end

		def use_binaries_selector
			get_internal_hash_value('use_binaries_selector', nil)
		end

		def use_binaries?
			get_internal_hash_value('use_binaries', false) || ENV['use_binaries'] == 'true'
		end

		def use_source_pods
			get_internal_hash_value('use_source_pods', []) + String(ENV['use_source_pods']).split('|').uniq
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