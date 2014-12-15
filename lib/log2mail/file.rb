
module Log2mail

  class File

    require_relative 'file/parser'
    include Parser


    # FIXME: redundant
    def log(msg, sev = ::Logger::DEBUG)
      $logger.log sev, '%s: %s%s  [%s]' % [@path, msg, $/, caller.first]
    end

    def warn(msg)
      log(msg, ::Logger::WARN)
    end

    attr_reader :path, :patterns

    def initialize( path, patterns, maxbufsize = 65536 )
      @path = path
      self.patterns = patterns
      @maxbufsize = maxbufsize
      log "Maximum buffer size: #{@maxbufsize}"
      log "Patterns: #{patterns.inspect}"
    end

    def patterns=(patterns)
      @patterns = patterns.map(&:to_r)
    end

    # ----------------------------
    # - File management (public) -
    # ----------------------------

    def open
      @f = ::File.open(@path, 'r', :encoding => "BINARY")
      log "file opened"
      @ino = @f.stat.ino
      @size = 0
      @f
    rescue Errno::ENOENT
      warn "does not exist"
      false
    end

    def seek_to_end
      @f.seek(0, IO::SEEK_END)
      @size = @f.stat.size
      @f
    end

    def read_to_end
      return unless @f
      s = @f.gets(nil)
      @size += s.length if s
      s
    end

    def eof?
      !@f or @f.eof?
    end

    def rotated?
      if inum_changed?
        log "inode number changed"
        true
      elsif file_size_changed?
        log "file size changed; probably truncated"
        true
      else
        false
      end
    end

    private

    # -------------------
    # - File management -
    # -------------------

    def inum_changed?
      ::File.stat(@path).ino != @ino
    rescue Errno::ENOENT
      true
    end

    def file_size_changed?
      @f.stat.size != @size
    end

  end

end