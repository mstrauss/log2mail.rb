require 'spec_helper'

module Log2mail

  describe ReportFactory do

    subject { ReportFactory.new( build(:valid_config) ) }
    before do

    end

    describe '.reports_from_hit' do
      subject { ReportFactory.new( build(:valid_config) ).reports_from_hit( build(:hit) ) }
      it { is_expected.to be_kind_of(Array) }
      it { is_expected.to all( be_kind_of(Log2mail::Report) ) }
    end

  end

  describe Report do
    describe '#body_from_template' do
      subject { build(:report).send(:body_from_template) }
      it 'should parse the template' do
        expect(subject).to eql(<<-EOS)
From: log2mail
To: recipient@example.org
Subject: matched your pattern: string match

Hello!

We have matched your pattern "string match" in "test.log" %n times:

a line with string match in it

Yours,
log2mail.
        EOS
      end
    end
    describe '#deliver' do
      include Mail::Matchers
      subject { build(:report).deliver }
      it { should have_sent_email }
      # it 'should send the message' do
      #   expect(subject.deliver).to change{Mail::TestMailer.deliveries.length}.by(1)
      # end
    end
    describe '#sendmail_command=' do
      let(:report){ build(:report) }
      it 'parses the sendmail command string with parameters' do
        report.sendmail_command = "/usr/local/sbin/sendmail -oi -t"
        expect(report.sendmail_location).to eql('/usr/local/sbin/sendmail')
        expect(report.sendmail_arguments).to eql('-oi -t')
      end
      it 'parses the sendmail command string without' do
        report.sendmail_command = "/usr/local/sbin/sendmail"
        expect(report.sendmail_location).to eql('/usr/local/sbin/sendmail')
        expect(report.sendmail_arguments).to be(nil)
      end
    end
  end

end
