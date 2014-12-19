module Log2mail
  module Config
    class Attribute
      attr_reader :name, :value
      def initialize( name, value )
        @name  = name.to_sym
        @value = value
      end
      def ==(other)
        self.name == other.name and self.value == other.value
      end
      def inspect
        'Attribute %s = %s' % [@name.inspect, @value.inspect]
      end
      def tree
        {self.name => self.value}
        # self.value
      end
    end
  end
end
