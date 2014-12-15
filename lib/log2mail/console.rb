class Log2mail::Console

  require_relative 'console/logger'
  require_relative 'console/commands'
  include Log2mail::Console::Commands
  require 'highline/import'

  def run

    # PFUSCH!!!
    # Log2mail::Config.extend Log2mail::Console::Logger
    # Log2mail::Config.include Log2mail::Console::Logger

    loop do
      input = ask('log2mail.rb % ').chomp
      # command, *params = input.split /\s/
      command = input
      next if command.empty?
      command.gsub!(' ', '_')
      (quit; return) if ['quit', 'exit'].include?(command)
      if self.commands.include?(command)
        send(command)
      else
        puts "Unknown command. Use 'help' for more information."
      end
    end
  rescue EOFError
    quit; return
  end

  def quit
    puts "quitting..."
  end

end
