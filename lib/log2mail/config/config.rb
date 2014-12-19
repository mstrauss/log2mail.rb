module Log2mail
  module Config
    class Config
      attr_reader :sections
      def initialize( sections = [] )
        @sections = merge sections
      end
      def ==(other)
        return false unless other.instance_of?(self.class)
        self.sections == other.sections
      end
      def inspect
        'Config: %s' % [@sections.inspect]
      end
      def tree
        h = {}
        @sections.inject(h) do |h, a|
          if a.name==:defaults
            h[:defaults] = a.tree
          else
            a.tree.each_pair {|k,v| ( h[a.name.pluralize.to_sym] ||= {} )[k] = v }
          end
          h
        end
        h
      end

      private

      # FIXME: needs specing
      def merge( sections )
        sections = sections.compact.find_all{ |s| s.respond_to?(:name) }
        names = sections.map(&:name).uniq
        names.map do |name|
          secs_with_same_name = sections.find_all{ |sec| sec.name == name }
          their_uniq_values = secs_with_same_name.map(&:value).uniq
          their_uniq_values.map{ |val| secs_with_same_name.find_all{ |s| s.value == val }.reduce(:+) }
        end.flatten(1)
      rescue NoMethodError
        fail "Invalid configuration: #{$!.inspect}"
      end

    end
  end
end
