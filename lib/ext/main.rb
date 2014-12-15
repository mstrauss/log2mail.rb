module Main
  class Program
    module InstanceMethods

      def logger= log
        unless(defined?(@logger) and @logger == log)
          case log
            when ::Logger, Logger, Syslog::Logger
              @logger = log
            else
              if log.is_a?(Array)
                @logger = Logger.new(*log)
              else
                @logger = Logger.new(log)
                @logger.level = logger_level
              end
          end
        end
        @logger
      end

    end
  end
end
