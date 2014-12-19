class String
  # based on https://www.ruby-forum.com/topic/193809#844629
  def to_r
    if self.strip.match(/\A\/(.*)\/(.*)\Z/mx)
      regexp, flags = $1, $2
      fail "Not a valid regular expression. Valid flags in (/regexp/flags) are x, i and m" \
        if !regexp || flags =~ /[^xim]/m

      x = /x/.match(flags) && Regexp::EXTENDED
      i = /i/.match(flags) && Regexp::IGNORECASE
      m = /m/.match(flags) && Regexp::MULTILINE

      rxp = Regexp.new regexp , [x,i,m].inject(0){|a,f| f ? a+f : a }
      def rxp.from_string?; false end
      rxp
    else
      # build regexp from regular string
      rxp = Regexp.new( self )
      def rxp.from_string?; true end
      rxp
    end
  end

  def pluralize
    return self if self.to_s[-1] == 's'
    (self.to_s + 's')
  end

end
