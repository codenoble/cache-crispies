require 'spec_helper'

describe CacheCrispies::Attribute do
  class NameSerializer < CacheCrispies::Base
    serialize :spanish
  end

  class ToHashClass
    def to_hash
      { portuguese: 'Capitão Crise' }
    end
  end

  let(:key) { :name }
  let(:from) { nil }
  let(:with) { nil }
  let(:through) { nil }
  let(:to) { nil }
  let(:nesting) { [] }
  let(:conditions) { [] }
  let(:instance) {
    described_class.new(
      key,
      from: from,
      with: with,
      through: through,
      to: to,
      nesting: nesting,
      conditions: conditions
    )
  }

  subject { instance }

  describe '#value_for' do
    let(:name) { "Cap'n Crunch" }
    let(:model) { OpenStruct.new(name: name) }
    let(:options) { {} }

    subject { instance.value_for(model, options) }

    it 'returns the value' do
      expect(subject).to eq name
    end

    context 'with a from: argument' do
      let(:key) { :nombre }
      let(:from) { :name }

      it 'returns the value using the from: attribute' do
        expect(subject).to eq name
      end
    end

    context 'with a with: argument' do
      let(:spanish_name) { 'Capitán Crujido' }
      let(:name) { OpenStruct.new(spanish: spanish_name)}
      let(:with) { NameSerializer }

      it 'returns the value using the from attribute' do
        expect(subject).to eq spanish: spanish_name
      end
    end

    context 'with a through: argument' do
      let(:through) { :branding }
      let(:model) { OpenStruct.new(branding: OpenStruct.new(name: name)) }

      it 'returns the value from the "through" object' do
        expect(subject).to eq name
      end

      context 'when the through method returns nil' do
        let(:model) { OpenStruct.new(branding: nil) }

        it 'returns nil' do
          expect(subject).to be nil
        end
      end
    end

    context 'with a to: argument' do
      context 'when corecing to a String' do
        let(:name) { 1138 }
        let(:to) { String }

        it 'returns a String' do
          expect(subject).to eq '1138'
        end
      end

      context 'when corecing to an Integer' do
        let(:name) { '1138' }
        let(:to) { Integer }

        it 'returns a String' do
          expect(subject).to eq 1138
        end
      end

      context 'when corecing to an Float' do
        let(:name) { '1138' }
        let(:to) { Float }

        it 'returns a String' do
          expect(subject).to eq 1138.0
        end
      end

      context 'when corecing to an BigDecimal' do
        let(:name) { '1138' }
        let(:to) { BigDecimal }

        it 'returns a String' do
          expect(subject).to eq BigDecimal(1138)
        end
      end

      context 'when corecing to an Array' do
        let(:name) { 1138 }
        let(:to) { Array }

        it 'returns an Array' do
          expect(subject).to eq [1138]
        end
      end

      context 'when corecing to a Hash' do
        let(:to) { Hash }

        context 'that responds to to_h' do
          let(:french_name) { 'capitaine croquer' }
          let(:name) { OpenStruct.new(french: french_name) }

          it 'returns a Hash' do
            expect(subject).to eq french: french_name
          end
        end

        context 'that responds to to_hash' do
          let(:name) { ToHashClass.new }

          it 'returns a Hash' do
            expect(subject).to eq portuguese: 'Capitão Crise'
          end
        end
      end

      context 'when corecing to an boolean' do
        let(:to) { :boolean }

        context 'when value is falsey' do
          let(:name) { nil }

          it 'returns false' do
            expect(subject).to be false
          end
        end

        context 'when value is truthy' do
          let(:name) { 'true' }

          it 'returns true' do
            expect(subject).to be true
          end
        end
      end

      context 'when corercing to an invalid type' do
        let(:to) { OpenStruct }

        it 'raises an exception' do
          expect { subject }.to raise_exception CacheCrispies::Attribute::InvalidCoercionType
        end
      end
    end

    context 'with a block' do
      let(:instance) {
        described_class.new(key) { |model, _opt| model.name.upcase }
      }

      it 'uses the return value of the block' do
        expect(subject).to eq "CAP'N CRUNCH"
      end
    end
  end
end
