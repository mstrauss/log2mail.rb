module Log2mail

  module Console::Commands

    class <<self

      def desc(description)
        @desc = description
      end

      def method_added(meth)
        @@meths ||= []
        meth = meth.to_s
        @@meths << [meth.gsub('_', ' '), @desc] if @desc
        # puts "Added method #{meth}. Desc: #{@desc.inspect}."
        # puts @@meths.inspect
        # meth
        # super
      end

    end

    protected

    def commands
      @@meths.map { |m| m.first.gsub(' ', '_') }
    end

    public

    desc "show list of available commands"
    def help
      @command_table ||= Terminal::Table.new :headings => ['command','description'], :rows => @@meths.sort
      puts @command_table
      true
    end

    desc "end console session"
    def quit; end
    def exit; end

    desc "show configuration"
    def config
      config_path = ask('configuration path? ').chomp
      config = Log2mail::Config.parse_config config_path
      puts "Defaults:"
      puts config.defaults
      puts "Settings:"
      puts config.formatted(false)
      puts "Effective settings:"
      puts config.formatted(true)
    end

  end

end
