require 'parallel'
require 'cocoapods'

module Pod
	class Installer
		# rewrite install_pod_sources
		alias_method :old_install_pod_sources, :install_pod_sources
    def install_pod_sources
    	if installation_options.install_with_multi_processes
	      @installed_specs = []
	      pods_to_install = sandbox_state.added | sandbox_state.changed
	      title_options = { :verbose_prefix => '-> '.green }
	      # 多进程下载，多线程时 log 会显著交叉，多线程好点
	      Parallel.each(root_specs.sort_by(&:name), in_processes: 10) do |spec|
	        if pods_to_install.include?(spec.name)
	          if sandbox_state.changed.include?(spec.name) && sandbox.manifest
	            current_version = spec.version
	            previous_version = sandbox.manifest.version(spec.name)
	            has_changed_version = current_version != previous_version
	            current_repo = analysis_result.specs_by_source.detect { |key, values| break key if values.map(&:name).include?(spec.name) }
	            current_repo &&= current_repo.url || current_repo.name
	            previous_spec_repo = sandbox.manifest.spec_repo(spec.name)
	            has_changed_repo = !previous_spec_repo.nil? && current_repo && (current_repo != previous_spec_repo)
	            title = "Installing #{spec.name} #{spec.version}"
	            title << " (was #{previous_version} and source changed to `#{current_repo}` from `#{previous_spec_repo}`)" if has_changed_version && has_changed_repo
	            title << " (was #{previous_version})" if has_changed_version && !has_changed_repo
	            title << " (source changed to `#{current_repo}` from `#{previous_spec_repo}`)" if !has_changed_version && has_changed_repo
	          else
	            title = "Installing #{spec}"
	          end
	          UI.titled_section(title.green, title_options) do
	            install_source_of_pod(spec.name)
	          end
	        else
	          UI.titled_section("Using #{spec}", title_options) do
	            create_pod_installer(spec.name)
	          end
	        end
	      end
	    else
	    	old_install_pod_sources
	    end
    end
	end
end