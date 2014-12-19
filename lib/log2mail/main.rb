Main {

  CONFIG_DEFAULT = '/etc/log2mail/config'
  PID_DEFAULT    = '/var/run/log2mail.rb.pid'
  LOG_DEFAULT    = '/var/log/log2mail.rb'

  version Log2mail::VERSION

  ### daemonizes!  DOES NOT WORK CORRECTLY => implementing own forking
  # daemonizes!

  $logger = logger
  logger_level Logger::INFO
  logger.formatter = Log2mail::LoggerFormatter if logger.tty?

  environment('LOG2MAIL_CONF') {
    argument_required
    defaults CONFIG_DEFAULT
    description 'the configuration file or directory'
    synopsis 'env LOG2MAIL_CONF=config_path'
  }
  option('config', 'c') {
    argument_required
    defaults CONFIG_DEFAULT
    # synopsis '--config=config_path, -c'
    description 'path of configuration file or directory'
  }
  # option('pidfile', 'p') {
  #   description 'path of PID file'
  # }
  option('verbose', 'v')

  usage['MAN PAGE'] = "type 'gem man log2mail' for more information"

  # usage['EXAMPLE USAGE'] = <<-EXAMPLES
  #   env LOG2MAIL_CONF=/usr/local/etc/log2mail.conf #{$0} start
  #     starts as daemon using configuration from '/usr/local/etc/log2mail.conf'
  # EXAMPLES
  #
  # usage['CONFIGURATION FILE EXAMPLE'] = <<-EXAMPLES
  #   defaults
  #     mailto = your@mail.address
  #   file = /var/log/mail.log
  #     pattern = status=bounced       # report bounced mail
  #   file = /var/log/syslog
  #     pattern = /(warning|error)/i   # report warnings and errors from syslog
  # EXAMPLES

  def after_parse_parameters
    if params['verbose'].given?
      logger.level = Logger::DEBUG
      $verbose = true
    else
      logger.level = logger_level
    end
    @config_path = params['config'].given? ? params['config'].value : params['LOG2MAIL_CONF'].value
    @config_path ||= CONFIG_DEFAULT
  end

  # returns the pid(s) of the daemon
  def daemon_pids
    prog_name = Log2mail::PROGNAME
    own_pid = Process.pid
    # FIXME: finding daemon pids by using pgrep is NOT 'optimal' :-)
    `pgrep -f #{prog_name}`.split.map(&:to_i) - [own_pid]
  end

  def daemon_running?
    !daemon_pids.empty?
  end

  mode 'start' do
    # option('daemonize', '-D') { description 'daemonize into background'}
    option('nofork', '-N') { description 'no daemonizing, stay in foreground'}
    option('sleeptime') {
      argument_required
      description 'polling interval [seconds]'
      cast :int
      defaults 60
    }
    option('maxbufsize') { argument_required; cast :int; default 65536 }
    def run
      fail "Not starting. Daemon running." if daemon_running? and !params['nofork'].value
      config = Log2mail::Config::ConfigFileHandler.parse_config @config_path
      unless params['nofork'].value
        Process.daemon
        $PROGRAM_NAME = Log2mail::PROGNAME
        $logger = Syslog::Logger.new(Log2mail::PROGNAME)
        $logger.formatter = Log2mail::LoggerFormatter
        def $logger.log(*a,&b)
          add(*a,&b)
        end
        logger $logger
        logger.info{'Deamon started.'}
        trap(:INT) do
          # for whatever reason, SIGINT is NOT LOGGED automatically like other signals (SIGTERM)
          fatal "SIGINT"
          exit(1)
        end
      end
      Log2mail::Watcher.new(config, params['sleeptime'].value).run
    end
  end

  mode 'stop' do
    def run
      if daemon_running?
        daemon_pids.each do |pid|
          info "Interrupting pid #{pid}..."
          Process.kill(:INT, pid)
        end
      else
        warn "No running daemon found."
      end
    rescue Errno::ENOENT
      fail "Require 'pgrep' on path."
    end
  end

  # TODO: add restart mode

  mode 'status' do
    def run
      unless daemon_running?
        warn "No running daemon found."
        exit 1
      else
        info 'Daemon running. PID: %s' % daemon_pids.join(', ')
      end
    end
  end

  mode 'configtest' do
    option('effective', 'e') { description 'show effective settings' }
    def run
      config = Log2mail::Config::ConfigFileHandler.parse_config @config_path
      puts config.formatted(params['effective'].value)
    end
  end

  mode 'console' do
    def run
      Log2mail::Console.new.run
    end
  end if Log2mail.const_defined?(:Console)

  alias_method :run, :help!
}
