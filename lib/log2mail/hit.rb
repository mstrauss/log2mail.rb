module Log2mail
  class Hit

    attr_reader :matched_text, :pattern, :file

    def initialize( text, pattern, file )
      @matched_text = text
      @pattern      = pattern
      @file         = file
    end

  end
end
