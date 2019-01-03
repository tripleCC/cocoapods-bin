require 'cocoapods-bin/installation_options'

module Pod
  class Installer
    class PodSourceInstaller
    	include Pod::Installer::InstallationOptions::Mixin
    	delegate_installation_options { Config.instance.podfile }

    	alias_method :old_verify_source_is_secure, :verify_source_is_secure
    	def verify_source_is_secure(root_spec)
    		# http source 默认不警告
    		old_verify_source_is_secure(root_spec) if installation_options.warn_for_unsecure_source?
    	end
    end
  end
end