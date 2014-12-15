require 'spec_helper'

module Log2mail
  describe File do

    context 'with nil file' do
      subject{ File.new(nil, []) }
      it{ expect(subject.instance_eval('@path')).to be(nil) }
      it{ expect(subject.read_to_end).to be(nil) }
      it{ expect{subject.open}.to raise_error(TypeError) }
    end

    context 'with good file' do
      subject{ build(:file) }
      context 'before open' do
        it{ expect(subject.instance_eval('@f')).to be(nil) }
        it{ expect(subject.eof?).to be(true) }
      end
      context 'after open' do
        before { subject.open }
        it{ expect(subject.instance_eval('@f')).not_to be(nil) }
        it{ expect(subject.eof?).to be(false) }
        it{ expect(subject.read_to_end).to start_with( 'Lorem ipsum dolor') }

        context 'at eof' do
          before { subject.read_to_end }
          it{ expect(subject.read_to_end).to be(nil) }
        end
      end
    end

  end
end
