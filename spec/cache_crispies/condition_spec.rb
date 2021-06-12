require 'spec_helper'

describe CacheCrispies::Condition do
  class TestSerializer < CacheCrispies::Base
    show_if :boolean_method? do
      serialize :name
    end

    def boolean_method?
    end
  end

  let(:block) { -> {} }
  let(:model) { OpenStruct.new(name: 'Name') }
  let(:serializer) { TestSerializer.new(model) }
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
      subject.true_for? serializer
    end

    context 'when the block has one argument' do
      let(:block) { ->(_arg1) { } }

      it 'calls the block with the model only' do
        expect(block).to receive(:call).with(model)
        subject.true_for? serializer
      end
    end

    context 'when the block has no arguments' do
      let(:block) { -> {} }

      it 'calls the block with no arguments' do
        expect(block).to receive(:call).with(no_args)
        subject.true_for? serializer
      end
    end

    context 'when the block is a symbol' do
      let(:block) { :boolean_method? }

      it 'calls the method on serializer instance' do
        expect(serializer).to receive(block).with(no_args)
        subject.true_for? serializer
      end
    end

    it 'returns a boolean' do
      expect(subject.true_for?(serializer)).to be true
    end
  end
end