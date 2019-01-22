require 'yaml'

module CBin
  class Config
    def config_file
      File.expand_path("#{Pod::Config.instance.home_dir}/bin.yml") 
    end


    def template_hash
      {
        'code_repo_url' => { description: '源码私有源 Git 地址', default: 'git@git.2dfire.net:ios/cocoapods-spec.git' },
        'binary_repo_url' => { description: '二进制私有源 Git 地址', default: 'git@git.2dfire.net:ios/cocoapods-spec-binary.git' },
        'binary_download_url' => { description: '二进制下载地址，内部会依次传入组件名称与版本，替换字符串中的 %s ', default: 'http://iosframeworkserver-shopkeeperclient.app.2dfire.com/download/%s/%s.zip' },
        # 'binary_type' => { description: '二进制打包类型', default: 'framework', selection: %w[framework library] },
        'download_file_type' => { description: '下载二进制文件类型', default: 'zip', selection: %w[zip tgz tar tbz txz dmg] },
      }
    end

    def sync_config(config) 
      File.open(config_file, 'w+') do |f|
        f.write(config.to_yaml)
      end
    end

    def default_config
      @default_config ||= Hash[template_hash.map { |k, v| [k, v[:default]] }]
    end

    private

    def load_config 
      if File.exists?(config_file)
        YAML.load_file(config_file)
      else 
        default_config
      end
    end

    def config 
      @config ||= begin 
        @config = OpenStruct.new load_config
        validate!
        @config
      end
    end

    def validate!
      template_hash.each do |k, v|
        selection = v[:selection]
        next if !selection || selection.empty? 
        config_value = @config.send(k)
        next unless config_value
        raise Pod::Informative, "#{k} 字段的值必须限定在可选值 [ #{selection.join(' / ')} ] 内".red unless selection.include?(config_value)
      end
    end

    def respond_to_missing?(method, include_private = false)
      config.respond_to?(method) || super
    end

    def method_missing(method, *args, &block)
      if config.respond_to?(method)
        config.send(method, *args)
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