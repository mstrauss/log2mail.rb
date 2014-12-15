# provides a formatter to be used on TTY
module Log2mail::LoggerFormatter

  class <<self

    LEVELS = ["DEBUG", "INFO", "WARN", "ERROR", "FATAL", "UNKNOWN"]

    # http://blog.bigbinary.com/2014/03/03/logger-formatting-in-rails.html
    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        "#{ msg.message } (#{ msg.class })\n  [" <<
        ( $verbose ? \
           (msg.backtrace || []).join("#$/  ") : \
           (msg.backtrace || []).first
        ) << ']'
      else
        msg.inspect
      end
    end

    def call(severity, datetime, progname, msg)
      sev = severity.instance_of?(Fixnum) ? LEVELS[severity] : severity
      '%s: %s' % [sev, msg2str(msg)] + $/
    end
  end

end
