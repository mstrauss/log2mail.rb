%w{ main mail terminal-table }.each {|r| require r}
%w{ kernel string main }.each {|r| require_relative "ext/#{r}"}
begin
  require 'syslog/logger'
rescue LoadError
  require_relative 'ext/syslog_logger'
end
%w{ version error logger_formatter config watcher hit report }.each {|r| require_relative "log2mail/#{r}"}
