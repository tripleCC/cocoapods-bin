require 'parallel'
require 'cocoapods'

module Pod
  class Installer
    class Analyzer
    	# > 1.5.3 版本
			# rewrite update_repositories
			#
			alias_method :old_update_repositories, :update_repositories
      def update_repositories
      	if installation_options.update_source_with_multi_processes
	      	# 并发更新私有源
	      	# 这里多线程会导致 pod update 额外输出 --verbose 的内容
	      	# 不知道为什么？
	      	Parallel.each(sources, in_processes: 4) do |source|
	          if source.git?
	            config.sources_manager.update(source.name, true)
	          else
	            UI.message "Skipping `#{source.name}` update because the repository is not a git source repository."
	          end
		      end
		      @specs_updated = true
      	else 
      		old_update_repositories
      	end
      end
    end
  end
end