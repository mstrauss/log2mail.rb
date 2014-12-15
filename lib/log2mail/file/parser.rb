module Log2mail

  module File::Parser

    def parse(multiline_text)
      return [] unless multiline_text
      empty_buf! unless @buf
      # add new text to parse buffer
      @buf = @buf << multiline_text
      hits = []
      @patterns.each do |pattern|
        matches = []
        if pattern.from_string?
          matches.concat @buf.lines.find_all{ |line| line.match(pattern) }
          matches.map!(&:chomp)
        else
          matches.concat @buf.gsub(pattern).collect.to_a
        end
        hits.concat matches.map { |match| Hit.new( match, pattern, @path ) }
      end
      unless hits.empty?
        log 'pattern match: ' + hits.inspect
        empty_buf! # match -> clear buffer
      else
        cleanup_buf! # no match -> just keep what's necessary
      end
      hits
    end

    # ---------------------
    # - Buffer management -
    # ---------------------

    def empty_buf!
      @buf = ''
    end

    def cleanup_buf!
      # FIXME: cleanup should clean up to latest match only OR upto last line (if from_string true)
      if @patterns.all? {|p| p.from_string? }
        empty_buf!
      else
        @buf = @buf.byteslice(-@maxbufsize/32,@maxbufsize) if @buf.bytesize > @maxbufsize
      end
    end

  end

end
