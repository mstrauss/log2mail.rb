require 'spec_helper'
require 'tempfile'

module Log2mail

  describe Config do

    subject { build(:valid_config) }

    describe '#config' do
      it 'logs a message' do
        expect($logger).to receive(:debug).with(/Reading configuration from/)
        subject
      end

      context 'with defaults' do
        it 'should return a valid config' do
          expect($logger).not_to receive(:warn)
          expect(subject.files).to eql(["test.log"])
          expect(subject.defaults).to eql({
            :sendtime   => 20,
            :resendtime => 50,
            :maxlines   => 7,
            :template   => "/tmp/mail_template",
            :fromaddr   => "log2mail",
            :sendmail   => "/usr/sbin/sendmail -oi -t",
            :mailtos    => ["global_default_recipient@example.org"],
          })
          expect(subject.patterns_for_file('test.log')).to eql(["/any/", "string match"])
          expect(subject.mailtos_for_pattern('test.log', 'string match')).to eql(["special@recipient"])
          expect(subject.mailtos_for_pattern('test.log', '/any/')).to eql(["global_default_recipient@example.org"])
        end
      end

      context 'without defaults' do
        subject { build(:valid_config_without_defaults) }
        it 'should return a valid config' do
          expect(subject.files).to eql(["test.log"])
          expect(subject.defaults).to eql({})
          expect(subject.patterns_for_file('test.log')).to eql(["/any/", "string match"])
          expect(subject.mailtos_for_pattern('test.log', 'string match')).to eql(["special@recipient"])
          expect(subject.mailtos_for_pattern('test.log', '/any/')).to eql([])
        end
        it 'should log warning when no recipients' do
          expect($logger).to receive(:warn).with(/Pattern.*has no recipients/)
          subject
        end
      end

      # it { is_expected.to eql build(:config) }
    end

    describe '#files' do
      it 'should return a list of files to watch' do
        expect(subject.files).to be_kind_of(Array)
        expect(subject.files).to eql(['test.log'])
      end
    end

    describe '#patterns_for_file' do
      it 'should return a list of patterns for file' do
        expect(subject.patterns_for_file('test.log')).to be_kind_of(Array)
      end
    end

    describe '#mailtos_for_pattern' do
      it 'should return a list of recipients for file' do
        expect(subject.mailtos_for_pattern('test.log', /any/)).to be_kind_of(Array)
      end
      it 'should return the global default recipient (if no sepcial recipient)' do
        expect(subject.mailtos_for_pattern('test.log', /any/)).to eql(["global_default_recipient@example.org"])
      end
      it 'should return the special recipient' do
        expect(subject.mailtos_for_pattern('test.log', 'string match')).to eql(["special@recipient"])
      end
    end

    describe '#settings_for_mailto' do
      it 'should return defaults, except for setting present' do
        expect(subject.settings_for_mailto('test.log', 'string match', 'special@recipient')).to eql({
          :sendtime   => 20,
          :resendtime => 50,
          :maxlines   => 99,
          :template   => "/tmp/mail_template",
          :fromaddr   => "log2mail",
          :sendmail   => "/usr/sbin/sendmail -oi -t",
        })
      end
      it 'should return defaults, if no setting is present' do
        expect(subject.settings_for_mailto('test.log', 'string match', 'global_default_recipient@example.org')).to eql({
          :sendtime   => 20,
          :resendtime => 50,
          :maxlines   => 7,
          :template   => "/tmp/mail_template",
          :fromaddr   => "log2mail",
          :sendmail   => "/usr/sbin/sendmail -oi -t",
        })
      end
    end

  end

end
