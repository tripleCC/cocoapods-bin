require 'yaml'
require 'cocoapods-bin/config/config'

module CBin
	class Config
		class Asker
			def show_prompt
        print ' > '.green
      end

      def ask_with_answer(question, pre_answer)
        print "\n#{question}\n"

        print "旧值：#{pre_answer}\n" unless pre_answer.nil?

        answer = ''
        loop do
          show_prompt
          answer = STDIN.gets.chomp

          if answer == '' && !pre_answer.nil?
            answer = pre_answer
            print answer.yellow
            print "\n"
          end

          break unless answer.empty?
        end

        answer
      end


      def wellcome_message
        print <<-EOF

开始设置二进制化初始信息.
所有的信息都会保存在 #{CBin.config.config_file} 文件中.
你可以在对应目录下手动添加编辑该文件. 文件包含的配置信息如下：

#{CBin.config.template_hash.to_yaml}
EOF
      end

      def done_message
        print "\n设置完成.\n".green
      end
		end
	end
end