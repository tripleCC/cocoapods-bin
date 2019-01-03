require 'cocoapods-bin/podfile'
require 'cocoapods-bin/sources_manager'
require 'cocoapods-bin/installation_options'

module Pod
	class Resolver
		old_resolver_specs_by_target = instance_method(:resolver_specs_by_target)
		define_method(:resolver_specs_by_target) do 
			resolver_specs_by_target = old_resolver_specs_by_target.bind(self).call()

			# 过滤出用户工程
			user_specs_by_target = resolver_specs_by_target.reject { |st| st.name.end_with?('_Tests') || st.name == 'Pods' }

			sources_manager = Config.instance.sources_manager
			use_source_pods = podfile.use_source_pods

			user_specs_by_target.each do |target, rspecs|
				# use_binaries 并且 use_source_pods 不包含
				use_binary_rspecs = if podfile.use_binaries? || podfile.use_binaries_selector
															rspecs.select do |rspec| 
																([rspec.name, rspec.root.name] & use_source_pods).empty? &&
																(podfile.use_binaries_selector.nil? || podfile.use_binaries_selector.call(rspec.spec))
															end
													  else
														  []
													  end

				resolver_specs_by_target[target] = rspecs.map do |rspec|
					# 含有 subspecs 的组件暂不处理
					next rspec if rspec.spec.subspec? || rspec.spec.subspecs.any?

					# 采用二进制依赖并且不为开发组件 (development pods 的 source 为 nil)
					use_binary = use_binary_rspecs.include?(rspec) && rspec.source
					source = use_binary ? sources_manager.binary_source : sources_manager.code_source 

					spec_version = rspec.spec.version
					begin
						# 从新 source 中获取 spec
						specification = source.specification(rspec.name, spec_version)
						# 组装新的 rspec ，替换原 rspec
						rspec = ResolverSpecification.new(specification, rspec.used_by_tests_only, source)
						rspec
					rescue Pod::StandardError => error 	
						# 没有从新的 source 找到对应版本组件，直接返回原 rspec
						UI.message "【#{rspec.spec.name} | #{spec_version}】组件无对应二进制版本 , 将采用源码依赖." if use_binary#.yellow 
						rspec
					end
				end.compact
			end

			resolver_specs_by_target
		end
	end
end