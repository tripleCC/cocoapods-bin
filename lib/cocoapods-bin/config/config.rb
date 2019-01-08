require 'yaml'

module CBin
	class Config
		def config_file
			File.expand_path("#{Pod::Config.instance.home_dir}/bin.yml") 
		end

		def template_hash
			{
				'code_repo_url' => '源码私有源 Git 地址，如> git@git.2dfire.net:ios/cocoapods-spec.git',
				'binary_repo_url' => '二进制私有源 Git 地址，如> git@git.2dfire.net:ios/cocoapods-spec-binary.git',
				'binary_download_url' => '二进制下载地址，内部会依次传入组件名称与版本，替换字符串中的 %s ，如> http://iosframeworkserver-shopkeeperclient.app.2dfire.com/download/%s/%s.zip'
			}
		end

		def sync_config(config) 
			File.open(config_file, 'w+') do |f|
        f.write(config.to_yaml)
      end
		end

		private

		def load_config 
			if File.exists?(config_file)
				YAML.load_file(config_file)
			else 
				Hash[template_hash.map { |k, v| [k, v.split('>', 2).last.strip] }]
			end
		end

		def respond_to_missing?(method, include_private = false)
			@config.respond_to?(method) || super
		end

		def method_missing(method, *args, &block)
			@config ||= OpenStruct.new load_config
			if @config.respond_to?(method)
				@config.send(method, *args)
			elsif template_hash.keys.include?(method.to_s)
				raise Pod::Informative, "#{method} 字段必须在配置文件 #{config_file} 中设置, 请执行 init 命令配置或手动修改配置文件".red
			else
				super
			end
		end
	end

	def self.config 
		@config ||= Config.new
	end	
end