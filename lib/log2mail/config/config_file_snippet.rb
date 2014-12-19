module Log2mail
  module Config

    class ConfigFileSnippet
      attr_reader :snippet, :filename
      def initialize( snippet, filename )
        @snippet  = snippet
        @filename = filename
      end

      def to_s
        @snippet
      end
    end

  end
end
