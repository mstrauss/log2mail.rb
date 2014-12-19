require 'tempfile'

FactoryGirl.define do

  factory :raw_config, class: String do
    trait :valid do
      initialize_with{ new <<-CONFIG }
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
    end

    trait :valid_without_defaults do
      initialize_with{ new <<-CONFIG }
file = test.log
  pattern = /any/
  pattern = string match
    mailto = special@recipient
      CONFIG
    end

    trait :valid_global_mailto_attributes do
      initialize_with{ new <<-CONFIG }
defaults
  mailto   = recipient@test.itstrauss.eu
  fromaddr = log2mail
file = test.log
  pattern = string pattern
  pattern = /regexp pattern/
      CONFIG
    end

    trait :valid_global_pattern_attributes do
      initialize_with{ new <<-CONFIG }
defaults
  pattern = recipient@test.itstrauss.eu
  mailto  = special recipient for pattern
file = test.log
      CONFIG
    end

    factory :valid_raw_config, traits: [:valid]
    factory :valid_raw_config_without_defaults, traits: [:valid_without_defaults]
    factory :valid_raw_config_with_defaults_with_global_mailto_attributes, traits: [:valid_global_mailto_attributes]
    factory :valid_raw_config_with_defaults_with_global_pattern_attributes, traits: [:valid_global_pattern_attributes]
  end

  factory :config, class: Log2mail::Config::ConfigFileHandler do

    factory :valid_config do
      initialize_with do
        tmp = Tempfile.new('valid_config')
        tmp.write build(:valid_raw_config)
        tmp.close
        new(tmp.path)
      end
    end

    factory :valid_config_without_defaults do
      initialize_with do
        tmp = Tempfile.new('valid_config')
        tmp.write build(:valid_raw_config_without_defaults)
        tmp.close
        new(tmp.path)
      end
    end
    factory :valid_config_with_defaults_with_global_mailto_attributes do
      initialize_with do
        tmp = Tempfile.new('valid_config')
        tmp.write build(:valid_raw_config_with_defaults_with_global_mailto_attributes)
        tmp.close
        new(tmp.path)
      end
    end
    factory :valid_config_with_defaults_with_global_pattern_attributes do
      initialize_with do
        tmp = Tempfile.new('valid_config')
        tmp.write build(:valid_raw_config_with_defaults_with_global_pattern_attributes)
        tmp.close
        new(tmp.path)
      end
    end

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

  sequence :snippet do |n|
    <<-TEXT
# this is file file#{n}
file = file#{n}
  pattern = for file#{n}
    mailto = for pattern for file#{n}
    TEXT
  end

  sequence :filename do |n|
    "config file #{n}"
  end


  factory :defaults_snippet, class: Log2mail::Config::ConfigFileSnippet do
    filename = '/config/defaults'
    snippet = <<-TEXT
# comment
defaults
mailto = global_default_recipient@example.org
    TEXT
    initialize_with do
      new(snippet, filename)
    end
  end

  factory :just_comments_snippet, class: Log2mail::Config::ConfigFileSnippet do
    filename = '/config/comments'
    snippet = <<-TEXT
# comment
# other comment
# even more important comment
    TEXT
    initialize_with do
      new(snippet, filename)
    end
  end

  factory :config_file_snippet, class: Log2mail::Config::ConfigFileSnippet do
    snippet
    filename
    initialize_with do
      new(snippet, filename)
    end

  end

end
