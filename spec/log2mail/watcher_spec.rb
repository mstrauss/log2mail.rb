require 'spec_helper'

module Log2mail

  describe Watcher do
    subject { Log2mail::Watcher.new( build(:valid_config ), 99 ) }

    describe '#new' do
      it 'should fail on invalid configuration' do
        expect{ Log2mail::Watcher.new('invalid config', 99) }.to raise_error(Log2mail::Error, /Invalid configuration/)
      end
      it 'should init @sleeptime' do
        expect(subject.instance_eval('@sleeptime')).to be(99)
      end
      it 'should init @factory' do
        expect(subject.instance_eval('@factory')).to be_instance_of(Log2mail::ReportFactory)
      end
      it 'should init @files' do
        files = subject.instance_eval('@files')
        expect(files).to all( be_instance_of(Log2mail::File))
        expect(files.count).to be(1)
      end
    end

    describe '#run' do
      let(:files) { subject.instance_eval('@files') }
      before do
        subject.instance_eval('@sleeptime=0')
        expect(subject).to receive(:running?).and_return(true, false)
      end
      it 'should open and seek all files in the beginning' do
        expect(subject).to receive(:open_and_seek_files)
        subject.run
      end
      it 'should should check eof? for each file' do
        files.each { |file| expect(file).to receive(:eof?).and_return(false) }
        subject.run
      end
      it 'should report any hits' do
        files.each do |file|
          expect(file).to receive(:eof?).and_return(false)
          hits = [build(:hit)]
          expect(file).to receive(:parse).and_return(hits)
          expect(subject).to receive(:report).with(hits)
        end
        subject.run
      end

      context 'rotated file' do
        before do
          allow(subject).to receive(:open_and_seek_files)
          files.each do |file|
            expect(file).to receive(:eof?).and_return(true)
            expect(file).to receive(:rotated?).and_return(true)
          end
        end
        it 'should reopen file if rotated' do
          files.each do |file|
            expect(file).to receive(:open).once
          end
          subject.run
        end
        it 'should report any hits' do
          files.each do |file|
            hits = [build(:hit)]
            expect(file).to receive(:parse).and_return(hits)
            expect(subject).to receive(:report).with(hits)
          end
          subject.run
        end
      end

    end

    # privates

    describe '#open_and_seek_files'

    describe '#log' do
      it 'should not fail' do
        expect{ subject.send(:log, 'a message') }.not_to raise_error
      end
    end

    describe '#report' do
      it 'should not fail' do
        expect{ subject.send(:report, [build(:hit)]) }.not_to raise_error
      end
    end

  end

end
