module Pod
	class Podfile
		module DSL
			def use_binaries!(flag = true)
				set_internal_hash_value('use_binaries', flag)
			end

			def set_use_source_pods(pods)
				hash_pods_use_source = get_internal_hash_value('use_source_pods') || []
				hash_pods_use_source += Array(pods)
				set_internal_hash_value('use_source_pods', hash_pods_use_source)
			end
		end

		def use_binaries?
			get_internal_hash_value('use_binaries', false)
		end

		def use_source_pods
			get_internal_hash_value('use_source_pods', [])
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