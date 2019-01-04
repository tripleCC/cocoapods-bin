require 'cocoapods-bin/config/config_asker'

module Pod
  class Command
    class Bin < Command
      class Init < Bin 
        self.summary = '初始化插件.'
        self.description = <<-DESC
          创建 #{CBin.config.config_file} 文件，在其中保存插件需要的配置信息，
          如二进制私有源地址、源码私有源地址等。
        DESC

        def run 
          asker = CBin::Config::Asker.new
          asker.wellcome_message

          config = {}
          template_hash = CBin.config.template_hash
          template_hash.each do |k, v|
            default = CBin.config.send(k) rescue nil
            config[k] = asker.ask_with_answer(v, default)
          end

          CBin.config.sync_config(config)
          asker.done_message
        end
      end
    end
  end
end
