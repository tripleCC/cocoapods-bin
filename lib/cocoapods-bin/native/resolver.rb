require 'parallel'
require 'cocoapods-bin/native/podfile'
require 'cocoapods-bin/native/sources_manager'
require 'cocoapods-bin/native/installation_options'
require 'cocoapods-bin/gem_version'

module Pod
	class Resolver
		# >= 1.4.0 才有 resolver_specs_by_target 以及 ResolverSpecification
		# >= 1.5.0 ResolverSpecification 才有 source，供 install 或者其他操作时，输入 source 变更
		#	
		if Pod.match_version?('~> 1.4') 
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

					# Parallel.map(rspecs, in_threads: 8) do |rspec| 
					resolver_specs_by_target[target] = rspecs.map do |rspec|
						# 含有 subspecs 的组件暂不处理
						next rspec if rspec.spec.subspec? || rspec.spec.subspecs.any?

						# developments 组件采用默认输入的 spec (development pods 的 source 为 nil)
						next rspec unless rspec.spec.respond_to?(:spec_source) && rspec.spec.spec_source

						# 采用二进制依赖并且不为开发组件 
						use_binary = use_binary_rspecs.include?(rspec)
						source = use_binary ? sources_manager.binary_source : sources_manager.code_source 

						spec_version = rspec.spec.version
						begin
							# 从新 source 中获取 spec
							specification = source.specification(rspec.name, spec_version)
							# 组装新的 rspec ，替换原 rspec
							rspec = if Pod.match_version?('~> 1.4.0')
												ResolverSpecification.new(specification, rspec.used_by_tests_only)
											else
												ResolverSpecification.new(specification, rspec.used_by_tests_only, source)
											end
							rspec
						rescue Pod::StandardError => error 	
							# 没有从新的 source 找到对应版本组件，直接返回原 rspec
							UI.message "【#{rspec.spec.name} | #{spec_version}】组件无对应二进制版本 , 将采用源码依赖." if use_binary#.yellow 
							rspec
						end

						rspec 
					end.compact
				end

				resolver_specs_by_target
			end
		end
	end

	if Pod.match_version?('~> 1.4.0')
		# 1.4.0 没有 spec_source
	  class Specification
	    class Set
	      class LazySpecification < BasicObject
	        attr_reader :spec_source

	        old_initialize = instance_method(:initialize)
					define_method(:initialize) do |name, version, source|
						old_initialize.bind(self).call(name, version, source)

						@spec_source = source 
					end

					def respond_to?(method, include_all = false) 
						return super unless method == :spec_source
						true
					end
	      end
	    end
	  end
	end
end

