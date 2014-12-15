require 'spec_helper'

module Log2mail

  describe File::Parser do

    subject{ build(:file) }

    describe '#parse' do

      context 'string pattern' do
        it 'returns the hits' do
          expect($logger).to receive(:log).with(0, /pattern match/)
          hits = subject.parse( IO.read(subject.path) )
          expect(hits.count).to be(3)
          expect(hits[0].matched_text).to eql('eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim')
        end
        it 'returns no hits' do
          expect($logger).not_to receive(:log).with(0, /pattern match/)
          hits = subject.parse( 'no hits here' )
          expect(hits.count).to be(0)
          expect(hits).to eql([])
        end
      end

      context 'regexp pattern' do
        it 'returns the hits' do
          expect($logger).to receive(:log).with(0, /pattern match/)
          subject.patterns = ['/ut/']
          hits = subject.parse( IO.read(subject.path) )
          expect(hits.count).to be(3)
          expect(hits.map(&:matched_text)).to all( eql('ut') )
        end
        it 'returns no hits' do
          expect($logger).not_to receive(:log).with(0, /pattern match/)
          hits = subject.parse( 'no hits here' )
          expect(hits.count).to be(0)
          expect(hits).to eql([])
        end
      end

      context 'mixed patterns' do
        it 'returns the hits' do
          expect($logger).to receive(:log).with(0, /pattern match/)
          subject.patterns = ['/ut/i', 'dolor']
          hits = subject.parse( IO.read(subject.path) )
          expect(hits.count).to be(8)
          expect(hits.map(&:matched_text)).to eql([
            "ut", "Ut", "ut", "ut",
            "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do",
            "eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim",
            "aliquip ex ea commodo consequat. Duis aute irure dolor in",
            "reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla"
          ])
        end
      end
    end

  end

end
