require_relative 'file'

module Log2mail
  class Watcher

    # class <<self
    #   attr_accessor :logfile, :maxbufsize
    #   attr_reader :pattern
    # end

    def initialize( config, sleeptime )
      fail Error, 'Invalid configuration.' unless config.instance_of?(Config::ConfigFileHandler)
      @file_patterns = config.file_patterns
      @files = @file_patterns.keys.map {|f| Log2mail::File.new(f, @file_patterns[f] ) }
      @sleeptime = sleeptime

      @report_queue = []
      @factory = ReportFactory.new(config)
    end

    def run
      open_and_seek_files
      loop do
        return unless running?
        @files.each do |file|
          if file.eof?
            file.open if file.rotated?
          end
          hits = file.parse(file.read_to_end)
          report hits unless hits.empty?
        end
        sleep @sleeptime
      end
    end

    private

    def running?
      true
    end

    def open_and_seek_files
      @files.each do |file|
        file.open and file.seek_to_end
      end
    end

    def log(msg, sev = ::Logger::DEBUG)
      $logger.log sev, '%s%s  [%s]' % [msg, $/, caller.first]
    end

    def report(hits)
      reports = hits.map { |hit| @factory.reports_from_hit( hit ) }.flatten
      reports.each do |report|
        log("Sending report: #{report.inspect}")
        report.deliver
      end
    end

  end
end
