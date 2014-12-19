module Log2mail
  module Config
    class ConfigFileHandler

      class <<self
        def parse_config(config_path)
          new(config_path)
        end
      end

      def initialize(config_paths)
        $logger.debug "Reading configuration from #{config_paths}"
        @config_paths = Array(config_paths)
        expand_paths
        @config = Parser.new.parse_snippets( raw ).tree
        validate_configuration
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

      def raw
        @config_paths.map do |file|
          ConfigFileSnippet.new( IO.read(file), file )
        end
      end

      # returns all the paths of all files needed to be watched
      def files
        Hash(@config[:files]).keys
      end

      # FIXME: specs
      def file_patterns
        h = {}
        files.each do |file|
          h[file] = patterns_for_file(file)
        end
        h
      end

      # returns the default settings
      def defaults
        Hash(@config[:defaults])
      end

      # returns all patterns for file
      def patterns_for_file( file )
        Hash(config_file(file)[:patterns]).keys + \
        Hash(defaults[:patterns]).keys
      end

      def mailtos_for_pattern( file, pattern )
        m = []
        m.concat Hash( config_file_pattern(file, pattern)[:mailtos] ).keys
        m.concat Hash(Hash(Hash(defaults[:patterns])[pattern])[:mailtos]).keys
        m.concat Hash(defaults[:mailtos]).keys if m.empty?
        m.uniq
      end

      def settings_for_mailto( file, pattern, mailto )
        h = defaults.reject {|k,v| k==:mailtos}
        h.merge config_file_mailto(file, pattern, mailto)
      end



      def formatted( show_effective = false )
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
        Hash(Hash(@config[:files])[file])
      end

      def config_file_pattern(file, pattern)
        Hash( Hash( config_file(file)[:patterns] )[pattern] )
      end

      def config_file_mailtos(file, pattern)
        config_file_pattern(file, pattern)[:mailtos] || {}
      end

      def config_file_mailto(file, pattern, mailto)
        config_file_mailtos(file, pattern)[mailto] || {}
      end


      def validate_configuration
        files.each do |file|
          patterns_for_file(file).each do |pattern|
            mailtos = mailtos_for_pattern(file, pattern)
            $logger.warn "Pattern #{file}:#{pattern} has no recipients." if mailtos.empty?
          end
        end

        $logger.warn "Attributes for a global default recipient specified. This may or may not be what you want. Consult `gem man log2mail` if unsure." \
          if !defaults[:mailtos].nil? and defaults[:mailtos].any?{|k,v| !v.empty? }

        $logger.warn "Attributes for a global default pattern specified. This may or may not be what you want. Consult `gem man log2mail` if unsure." \
          if !defaults[:patterns].nil? and defaults[:patterns].any?{|k,v| !v.empty? }

        # FIXME: empty configuration should cause FATAL error
        # TODO: illegal regexp pattern should cause ERROR
      end


    end
  end
end
