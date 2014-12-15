require 'tempfile'

FactoryGirl.define do
  factory :config, class: Log2mail::Config do

    trait :valid do
      initialize_with do
        tmp = Tempfile.new('valid_config')
        tmp.write <<-CONFIG
          # sample config file for log2mail
          # comments start with '#'
          # see source code doc/Configuration for additional information

          defaults
            sendtime   = 20
            resendtime = 50
            maxlines   = 7
            template   = /tmp/mail_template
            fromaddr   = log2mail
            sendmail   = /usr/sbin/sendmail -oi -t
            mailto     = global_default_recipient@example.org  # new in log2mail.rb
          file = test.log
            pattern = /any/
            pattern = string match
              mailto = special@recipient
                maxlines = 99
        CONFIG
        tmp.close
        new(tmp.path)
      end
    end

    trait :valid_without_defaults do
      initialize_with do
        tmp = Tempfile.new('valid_config')
        tmp.write <<-CONFIG
          file = test.log
            pattern = /any/
            pattern = string match
              mailto = special@recipient
        CONFIG
        tmp.close
        new(tmp.path)
      end
    end

    factory :valid_config, traits: [:valid]
    factory :valid_config_without_defaults, traits: [:valid_without_defaults]
  end

  factory :hit, class: Log2mail::Hit do
    matched_text "a line with string match in it\n"
    pattern 'string match'
    file 'test.log'
    initialize_with{ new(matched_text, pattern, file) }
  end

  factory :report, class: Log2mail::Report do
    recipients 'recipient@example.org'
    hit { build(:hit) }

    template do
      tmp = Tempfile.new('valid_config')
      tmp.write <<-TEMPLATE
From: %f
To: %t
Subject: matched your pattern: %m

Hello!

We have matched your pattern "%m" in "%F" %n times:

%l

Yours,
log2mail.
      TEMPLATE
      tmp.close
      tmp.path
    end

  end

  factory :file, class: Log2mail::File do
    initialize_with do
      tmp = Tempfile.new('file')
      tmp.write <<-FILE
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.
      FILE
      tmp.close
      new( tmp.path, ['ut'] )
    end
  end

end
