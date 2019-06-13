require 'parallel'
require 'cocoapods'
require 'cocoapods-bin/native/podfile'
require 'cocoapods-bin/native/sources_manager'
require 'cocoapods-bin/native/installation_options'
require 'cocoapods-bin/gem_version'

module Pod
  class Resolver

    if Pod.match_version?('~> 1.6')
      # 其实不用到 resolver_specs_by_target 再改 spec
      # 在这个方法里面，通过修改 dependency 的 source 应该也可以
      # 就是有一点，如果改了之后，对应的 source 没有符合 dependency 的版本
      # 分析依赖阶段就会报错了，没法像 resolver_specs_by_target 一样
      # 没有对应的二进制版本时还可以转到源码源码
      #
      def aggregate_for_dependency(dependency)
        sources_manager = Config.instance.sources_manager
        if dependency && dependency.podspec_repo
          sources_manager.aggregate_for_dependency(dependency)
        # 采用 lock 中的 source ，会导致插件对 source 的先后调整失效
        # elsif (locked_vertex = @locked_dependencies.vertex_named(dependency.name)) && (locked_dependency = locked_vertex.payload) && locked_dependency.podspec_repo
        #   sources_manager.aggregate_for_dependency(locked_dependency)
        else
          @aggregate ||= Source::Aggregate.new(sources)
        end
      end
    end


    if Pod.match_version?('~> 1.4') 
      def specifications_for_dependency(dependency, additional_requirements = [])
        additional_requirements.compact!
        requirement = Requirement.new(dependency.requirement.as_list + additional_requirements.flat_map(&:as_list))
        requirement = Requirement.new(dependency.requirement.as_list.map { |r| r + '.a' } + additional_requirements.flat_map(&:as_list)) if podfile.allow_prerelease? && !requirement.prerelease?

        if Pod.match_version?('~> 1.7') 
          options = podfile.installation_options
        else
          options = installation_options
        end

        find_cached_set(dependency).
          all_specifications(options.warn_for_multiple_pod_sources).
          select { |s| requirement.satisfied_by? s.version }.
          map { |s| s.subspec_by_name(dependency.name, false, true) }.
          compact
      end
    end

    if Pod.match_version?('~> 1.6') 
      alias_method :old_valid_possibility_version_for_root_name?, :valid_possibility_version_for_root_name?
      def valid_possibility_version_for_root_name?(requirement, activated, spec)
        return true if podfile.allow_prerelease?
        old_valid_possibility_version_for_root_name?(requirement, activated, spec)
      end
    elsif Pod.match_version?('~> 1.4')
      def requirement_satisfied_by?(requirement, activated, spec)
        version = spec.version
        return false unless requirement.requirement.satisfied_by?(version)
        shared_possibility_versions, prerelease_requirement = possibility_versions_for_root_name(requirement, activated)
        return false if !shared_possibility_versions.empty? && !shared_possibility_versions.include?(version)
        return false if !podfile.allow_prerelease? && version.prerelease? && !prerelease_requirement
        return false unless spec_is_platform_compatible?(activated, requirement, spec)
        true
      end
    end

    # >= 1.4.0 才有 resolver_specs_by_target 以及 ResolverSpecification
    # >= 1.5.0 ResolverSpecification 才有 source，供 install 或者其他操作时，输入 source 变更
    # 
    if Pod.match_version?('~> 1.4') 
      old_resolver_specs_by_target = instance_method(:resolver_specs_by_target)
      define_method(:resolver_specs_by_target) do 
        specs_by_target = old_resolver_specs_by_target.bind(self).call()

        sources_manager = Config.instance.sources_manager
        use_source_pods = podfile.use_source_pods

        missing_binary_specs = []
        specs_by_target.each do |target, rspecs|
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
          specs_by_target[target] = rspecs.map do |rspec|
            # 含有 subspecs 的组件暂不处理
            # next rspec if rspec.spec.subspec? || rspec.spec.subspecs.any?

            # developments 组件采用默认输入的 spec (development pods 的 source 为 nil)
            next rspec unless rspec.spec.respond_to?(:spec_source) && rspec.spec.spec_source

            # 采用二进制依赖并且不为开发组件 
            use_binary = use_binary_rspecs.include?(rspec)
            source = use_binary ? sources_manager.binary_source : sources_manager.code_source 

            spec_version = rspec.spec.version

            UI.message "- 开始处理 #{rspec.spec.name} #{spec_version} 组件." 

            begin
              # 从新 source 中获取 spec
              specification = source.specification(rspec.root.name, spec_version)   

              # 组件是 subspec
              specification = specification.subspec_by_name(rspec.name, false, true) if rspec.spec.subspec?
              # 这里可能出现分析依赖的 source 和切换后的 source 对应 specification 的 subspec 对应不上
              # 造成 subspec_by_name 返回 nil，这个是正常现象
              next unless specification

              if Pod.match_version?('~> 1.7')
                used_by_only = rspec.used_by_non_library_targets_only
              else
                used_by_only = rspec.used_by_tests_only
              end
              # used_by_only = rspec.respond_to?(:used_by_tests_only) ? rspec.used_by_tests_only : rspec.used_by_non_library_targets_only
              # 组装新的 rspec ，替换原 rspec
              rspec = if Pod.match_version?('~> 1.4.0')
                        ResolverSpecification.new(specification, used_by_only)
                      else
                        ResolverSpecification.new(specification, used_by_only, source)
                      end
              rspec
            rescue Pod::StandardError => error  
              # 没有从新的 source 找到对应版本组件，直接返回原 rspec
              missing_binary_specs << rspec.spec if use_binary
              rspec
            end

            rspec 
          end.compact
        end

        missing_binary_specs.uniq.each do |spec| 
          UI.message "【#{spec.name} | #{spec.version}】组件无对应二进制版本 , 将采用源码依赖." 
        end if missing_binary_specs.any?

        specs_by_target
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

