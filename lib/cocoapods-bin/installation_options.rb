
module Pod
  class Installer
    class InstallationOptions
    	# 不同 source 存在相同 spec 名时，默认不警告
    	defaults.delete('warn_for_multiple_pod_sources')
    	option :warn_for_multiple_pod_sources, false
    end
  end
end