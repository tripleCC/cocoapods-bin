module Pod
  class Command
    class Bin < Command
      class Search < Bin 
        self.summary = '查找二进制 spec.'

        self.arguments = [
          CLAide::Argument.new('QUERY', true),
        ]

        def self.options
          [
            ['--code', '查找源码 spec'],
            ['--stats', '展示额外信息'],
            ['--no-pager', '不以 pager 形式展示'],
            ['--regex', '`QUERY` 视为正则'],
          ]
        end

        def initialize(argv)
          @code = argv.flag?('code')
          @stats = argv.flag?('stats')
          @use_pager = argv.flag?('pager', true)
          @use_regex = argv.flag?('regex')
          @query = argv.arguments! unless argv.arguments.empty?
          super
        end

        def validate!
          super
          help! '必须指定查找的组件.' unless @query
        end

        def run 
          query_regex = @query.reduce([]) { |result, q|
            result << (@use_regex ? q : Regexp.escape(q))
          }.join(' ').strip 

          source = @code ? code_source : binary_source

          aggregate = Pod::Source::Aggregate.new([source])
          sets = aggregate.search_by_name(query_regex, true)

          if(@use_pager)
            UI.with_pager { print_sets(sets) }
          else
            print_sets(sets)
          end
        end

        def print_sets(sets)
          sets.each do |set|
            begin
              if @stats
                UI.pod(set, :stats)
              else
                UI.pod(set, :normal)
              end
            rescue DSLError
              UI.warn "Skipping `#{set.name}` because the podspec contains errors."
            end
          end
        end
      end
    end
  end
end
