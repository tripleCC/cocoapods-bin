module Pod
  class Source
    class Manager
    	# 源码 source
    	def code_source
    		source_with_name_or_url('git@git.2dfire.net:qingmu/cocoapods-spec.git')
    	end

    	# 二进制 source
    	def binary_source
    		source_with_name_or_url('git@git.2dfire.net:qingmu/binary-cocoapods-spec.git')
    	end
    end
  end
end