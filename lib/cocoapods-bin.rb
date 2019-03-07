require 'cocoapods-bin/gem_version'
require 'cocoapods-bin/native/sources_manager'


p '============='
p '============='
module Pod
  class Command
    class Update < Command
    	def initialize(argv)
        @pods = argv.arguments! unless argv.arguments.empty?

        p config.lockfile

        source_urls = argv.option('sources', '').split(',')
        excluded_pods = argv.option('exclude-pods', '').split(',')
        unless source_urls.empty?
          source_pods = source_urls.flat_map { |url| config.sources_manager.source_with_name_or_url(url).pods }
          unless source_pods.empty?
            source_pods = source_pods.select { |pod| config.lockfile.pod_names.include?(pod) }
            if @pods
              @pods += source_pods
            else
              @pods = source_pods unless source_pods.empty?
            end
          end
        end

        unless excluded_pods.empty?
          @pods ||= config.lockfile.pod_names.dup

          non_installed_pods = (excluded_pods - @pods)
          unless non_installed_pods.empty?
            pluralized_words = non_installed_pods.length > 1 ? %w(Pods are) : %w(Pod is)
            message = "Trying to skip `#{non_installed_pods.join('`, `')}` #{pluralized_words.first} " \
                    "which #{pluralized_words.last} not installed"
            raise Informative, message
          end

          @pods.delete_if { |pod| excluded_pods.include?(pod) }
        end

        super
      end
    end
  end
end