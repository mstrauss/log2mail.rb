module Log2mail
  module Config
    class Section
      attr_reader :name, :value
      attr_accessor :attrs
      def initialize( name, value = nil, attrs = [] )
        @name  = name.to_sym
        @value = value
        @attrs = attrs
      end
      def ==(other)
        return false unless other.instance_of?(self.class)
        self.name == other.name and self.value == other.value and self.attrs == other.attrs
      end
      def inspect
        'Section %s = %s---%s' % [@name.inspect, @value.inspect, @attrs.inspect]
      end
      def tree
        h = {}
        @attrs.inject(h) do |h, a|
          if a.instance_of?(Section)
            name = a.name.pluralize.to_sym
            unless a.attrs.empty?
              apdx = {a.value => a.tree}
            else
              apdx = a.value
            end
            case apdx
            when Hash
              apdx.each_pair{ |k,v| ( h[name] ||= {} )[k] = v }
            when Array
              fail "do not know what to do"
            else
              ( h[name] ||= {} )[apdx] = {}
            end
          else
            name = a.name
            h[name] = a.value
          end
          h
        end
        if @name==:file
          return {self.value => h}
          # unless @attrs.empty?
          #   return {self.value => h}
          # else
          #   return self.value
          # end
        end
        h
      end

      # merges sections by prefering other's attributes
      # FIXME: needs specing
      def +(other)
        fail "Unmergable sections:\n1) #{self.inspect}\n2) #{other.inspect}\nReason: values must differ." unless self.value == other.value
        @attrs.each do |a|
          case a
          when Attribute
            other.attrs << a unless other.attrs.map(&:name).include?(a.name)
          when Section
            other.attrs << a
          end
        end
        other
      end

    end
  end
end
