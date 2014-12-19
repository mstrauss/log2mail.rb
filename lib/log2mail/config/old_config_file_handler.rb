require_relative 'attribute'
require_relative 'section'

module Log2mail
  module Config
    class ConfigFileHandler

      class <<self
        def parse_config(config_path)
          new(config_path)
          # pp config.config
          # config.files.each do |f|
          #   puts "File: #{f}"
          #   config.patterns_for_file(f).each do |pattern|
          #     puts "  Pattern: #{pattern}; mailto: " + config.mailtos_for_pattern( f, pattern ).join(', ')
          #   end
          # end
        end
      end

      attr_reader :raw

      def initialize(config_paths)
        $logger.debug "Reading configuration from #{config_paths}"
        @config_paths = Array(config_paths)
        expand_paths
        @raw = read_configuration
        validate_configuration
      end

      # returns all the paths of all files needed to be watched
      def files
        @config.keys - [:defaults]
      end

      def file_patterns
        h = {}
        files.each do |file|
          h[file] = patterns_for_file(file)
        end
        h
      end

      def patterns_for_file( file )
        Hash(@config[file][:patterns]).keys + \
        Hash(defaults[:patterns]).keys
      end

      def mailtos_for_pattern( file, pattern )
        m = []
        m.concat Hash( config_file_pattern(file, pattern)[:mailtos] ).keys
        m.concat Hash(Hash(Hash(defaults[:patterns])[pattern])[:mailtos]).keys
        m.concat Array(defaults[:mailtos]) if m.empty?
        m.uniq
      end

      def settings_for_mailto( file, pattern, mailto )
        h = defaults.reject {|k,v| k==:mailtos}
        h.merge config_file_mailto(file, pattern, mailto)
      end

      def defaults
        Hash(@config[:defaults])
      end

      def formatted( show_effective )
        Terminal::Table.new do |t|
          settings_header = show_effective ? 'Effective Settings' : 'Settings'
          t << ['File', 'Pattern', 'Recipient', settings_header]
          t << :separator
          files.each do |file|
            patterns_for_file(file).each do |pattern|
              mailtos_for_pattern(file, pattern).each do |mailto|
                settings = []
                if show_effective
                  settings_for_mailto(file, pattern, mailto).each_pair \
                    { |k,v| settings << '%s=%s' % [k,v] }
                else
                  config_file_mailto(file, pattern, mailto).each_pair \
                    { |k,v| settings << '%s=%s' % [k,v] }
                end
                t.add_row [file, pattern, mailto, settings.join($/)]
              end
            end
          end
        end
      end

      private

      def config_file(file)
        Hash(@config[file])
      end

      def config_file_pattern(file, pattern)
        Hash( Hash( config_file(file)[:patterns] )[pattern] )
      end

      def config_file_mailtos(file, pattern)
        Hash( config_file_pattern(file, pattern)[:mailtos] )
      end

      def config_file_mailto(file, pattern, mailto)
        Hash( config_file_mailtos(file, pattern)[mailto] )
      end

      def expand_paths
        expanded_paths = []
        @config_paths.each do |path|
          if ::File.directory?(path)
            expanded_paths.concat Dir.glob( ::File.join( path, '*[^~#]' ) )
          else
            expanded_paths << path
          end
        end
        @config_paths = expanded_paths
      end

      # tries to follow original code at https://github.com/lordlamer/log2mail/blob/master/config.cc#L192
      def read_configuration
        @config = {}
        @config_paths.map do |file|
          @section = nil; @pattern = nil; @mailto = nil
          # section, pattern, mailto are reset for every file (but not when included by 'include')
          parse_file( file )
        end.join($/)
      end

      def parse_file( filename )
        raw = ""
        IO.readlines(filename).each_with_index do |line, lineno|
          raw << line
          parse(filename, line, lineno + 1)
        end
        raw
      rescue Errno::ENOENT
        fail Error, "Configuration file or directory not found (or not readable): #{filename}"
      end

      def parse(file, line, lineno)
        line.strip!
        return if line =~ /^#/
        return if line =~ /^$/
        line =~ /^(\S+)\s*=?\s*"?(.*?)"?(\s*#.*)?$/  # drop double quotes on right hand side; drop comments
        key, value = $1.to_sym, $2.strip
        if key == :include # include shall work everywhere
          parse_file( ::File.join(Pathname(file).parent, value) )
          return
        end
        if key == :defaults and value.empty?  # section: specifies top level; must be 'defaults' or 'file'
          @section = key
          @pattern = nil; @mailto = nil
          fail Error, "Invalid section. Section 'defaults' already specified." if @config[@section]
          @config[@section] = {}
        elsif key == :file
          @section = value
          @pattern = nil; @mailto = nil
          @config[@section] ||= {}
        elsif key == :pattern # must come inside 'file' (or 'defaults')
          # fail "Invalid section. All statements must appear after 'defaults' or 'file=...'" unless @section
          @pattern = value; @mailto = nil
          @config[@section][:patterns] ||= {}
          warning { "Redefining pattern section '#{value}' which has been defined already for '#{@section}'." } \
            if @config[@section][:patterns][value]
          @config[@section][:patterns][value] = {}
        elsif key == :mailto and @section != :defaults # must come inside 'pattern' (or 'defaults')
          fail Error, "'mailto' statements only allowed inside 'pattern' or 'defaults'." unless @pattern
          @mailto = value
          @config[@section][:patterns][@pattern][:mailtos] ||= {}
          warning { "Redefining mailto section '#{value}' which has been defined already for '#{@section}'." } \
            if @config[@section][:patterns][@pattern][:mailtos][value]
          @config[@section][:patterns][@pattern][:mailtos][value] = {}
        else # everything else must come inside 'defaults' or 'mailto'
          fail Error, "'#{key}' must be set within 'defaults' or 'mailto'." unless @section == :defaults or @mailto
          if INT_OPTIONS.include?(key)
            value = value.to_i
          elsif STR_OPTIONS.include?(key)
          elsif PATH_OPTIONS.include?(key)
            value = ::File.expand_path( value, Pathname(file).parent ) unless Pathname(value).absolute?
          elsif key == :mailto # special handling for 'mailto' in 'defaults' section
            @config[:defaults][:mailtos] ||= []
            @config[:defaults][:mailtos] << value
            return # skip the 'mailto' entry itself
          else
            fail Error, "'#{key}' is an unknown configuration statement."
          end
          if @section == :defaults and !@pattern and !@mailto
            warning { "Redefining value for '#{key}'." } if @config[@section][key]
            @config[@section][key] = value
          else
            warning { "Redefining value for '#{key}'." } \
              if @config[@section][:patterns][@pattern][:mailtos][@mailto][key]
            @config[@section][:patterns][@pattern][:mailtos][@mailto][key] = value
          end
        end
      rescue
        fail Error, "#{file} (line #{lineno}): #{$!.message}#$/[#{$!.class} at #{$!.backtrace.first}]"
      end

      def validate_configuration
        files.each do |file|
          patterns_for_file(file).each do |pattern|
            mailtos = mailtos_for_pattern(file, pattern)
            $logger.warn "Pattern #{file}:#{pattern} has no recipients." if mailtos.empty?
          end
        end
        # FIXME: empty configuration should cause FATAL error
        # TODO: illegal regexp pattern should cause ERROR
      end

      def warning(&block)
        file = block.binding.eval('file')
        lineno = block.binding.eval('lineno')
        message = block.call
        $logger.warn "#{file} (line #{lineno}): #{message}#$/[at #{caller.first}]"
      end

    end
  end
end
