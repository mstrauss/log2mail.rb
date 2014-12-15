module Log2mail

  module Console::Logger

    def info(msg)
      puts msg
    end

    def fatal(msg)
      puts "FATAL: " + msg
    end

    def warn(msg)
      puts "WARNING: " + msg
    end

    def debug(msg)
      puts "DEBUG: " + msg
    end

  end

end
