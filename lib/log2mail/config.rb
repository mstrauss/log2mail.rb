module Log2mail
  module Config
    INT_OPTIONS = [:sendtime, :resendtime, :maxlines]
    STR_OPTIONS = [:fromaddr, :sendmail]
    PATH_OPTIONS = [:template]
    ATTRIBUTES = INT_OPTIONS + STR_OPTIONS + PATH_OPTIONS
  end
end

require_relative 'config/config'
require_relative 'config/attribute'
require_relative 'config/section'
require_relative 'config/parser'
require_relative 'config/config_file_snippet'
require_relative 'config/config_file_handler'
