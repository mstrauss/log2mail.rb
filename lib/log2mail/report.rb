module Log2mail

  class ReportFactory

    def initialize( config )
      @config = config
    end

    def reports_from_hit( hit )
      reps = []
      mailtos = @config.mailtos_for_pattern( hit.file, hit.pattern )
      mailtos.each do |mailto|
        settings           = @config.settings_for_mailto( hit.file, hit.pattern, mailto )
        r                  = Report.new
        r.recipients       = mailto
        r.from             = settings[:fromaddr] if settings[:fromaddr]
        r.template         = settings[:template] if settings[:template]
        r.sendmail_command = settings[:sendmail] if settings[:sendmail]
        r.hit              = hit
        reps << r
      end
      reps
    end

  end


  class Report

    attr_accessor :recipients, :from, :subject, :template
    attr_accessor :hit

    attr_reader :sendmail_location, :sendmail_arguments

    def initialize
      @recipients = []
      @from       = "log2mail"
      @subject    = "[Log2mail]"
    end

    def deliver
      m = Mail.new
      m.to      = Array(@recipients).join(',')
      m.from    = @from
      m.subject = @subject
      m.body    = body_from_template
      if @sendmail_location
        m.delivery_method :sendmail, :location => @sendmail_location, :arguments => String(@sendmail_arguments)
      end
      m.deliver!
      $logger.info "Delivered report to #{m.to}."
      # FIXME: state message id instead full report
      $logger.debug m.to_s
    rescue
      # FIXME: state message id instead full report
      $logger.warn "Failed to deliver report: #{m}. Reason: #{$!.inspect}"
    end

    def sendmail_command=(txt)
      return unless txt
      s = txt.split(/^(\S+)\s*(.*)$/)
      @sendmail_location  = s[1]
      @sendmail_arguments = s[2]
      self
    end

    private

    def body_from_template
      if @template
        template = IO.read(@template)
      else
        template = <<-TEMPLATE
Hello!

We have matched your pattern "%m" in "%F" %n times:

%l

Yours,
log2mail.
        TEMPLATE
      end
      template.gsub!('%f', @from)
      template.gsub!('%t', Array(@recipients).join(', '))
      template.gsub!('%m', String(@hit.pattern) )
      template.gsub!('%F', @hit.file)
      template.gsub!('%l', @hit.matched_text.chomp)
    end

  end
end
