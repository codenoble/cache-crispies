require 'spec_helper'

describe CacheCrispies::Condition do
  let(:block) { -> {} }
  subject { described_class.new(block) }

  describe '#uid' do
    it "is the same as the block's object_id" do
      expect(subject.uid).to be block.object_id
    end
  end

  describe '#true_for?' do
    let(:block) { ->(_arg1, _arg2) { 'truthy string' } }
    let(:model) { Object.new }
    let(:options) { {} }

    it 'calls the block with model and options arguments' do
      expect(block).to receive(:call).with(model, options)
      subject.true_for? model, options
    end

    context 'when the block has one argument' do
      let(:block) { ->(_arg1) { } }

      it 'calls the block with the model only' do
        expect(block).to receive(:call).with(model)
        subject.true_for? model, options
      end
    end

    context 'when the block has no arguments' do
      let(:block) { -> {} }

      it 'calls the block with no arguments' do
        expect(block).to receive(:call).with(no_args)
        subject.true_for? model, options
      end
    end

    it 'returns a boolean' do
      expect(subject.true_for?(model, options)).to be true
    end
  end
end