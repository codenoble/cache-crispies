require 'spec_helper'

describe CacheCrispies::Collection do
  class UncacheableCerealSerializerForCollection < CacheCrispies::Base
    serialize :name
  end

  class CacheableCerealSerializerForCollection < CacheCrispies::Base
    serialize :name

    def self.do_caching?
      true
    end
  end

  let(:name1) { 'Cinnamon Toast Crunch' }
  let(:name2) { 'Cocoa Puffs' }
  let(:model1) { OpenStruct.new(name: name1) }
  let(:model2) { OpenStruct.new(name: name2) }
  let(:uncacheable_models) { [model1, model2] }
  let(:cacheable_models) {
    [model1, model2].tap do |models|
      def models.cache_key() end
    end
  }
  let(:collection) { cacheable_models }
  let(:serializer) { CacheableCerealSerializerForCollection }
  let(:options) { {} }
  subject { described_class.new(collection, serializer, options) }

  describe '#as_json' do
    context "when it's not cacheable" do
      context 'because the collection is not cacheable' do
        let(:collection) { uncacheable_models }

        it "doesn't cache the results" do
          expect(CacheCrispies::Plan).to_not receive(:new)
          expect(CacheCrispies).to_not receive :cache
          expect(subject.as_json).to eq [ {name: name1}, {name: name2} ]
        end
      end

      context 'because the serializer is not cacheable' do
        let(:serializer) { UncacheableCerealSerializerForCollection }

        it "doesn't cache the results" do
          expect(CacheCrispies::Plan).to_not receive(:new)
          expect(CacheCrispies).to_not receive :cache
          expect(subject.as_json).to eq [ {name: name1}, {name: name2} ]
        end
      end
    end

    context 'when it is cacheable' do
      it 'caches the results' do
        expect(CacheCrispies::Plan).to receive(:new).with(
          serializer, model1, options
        ).and_return double('plan-dbl-1', cache_key: 'cereal-key-1')

        expect(CacheCrispies::Plan).to receive(:new).with(
          serializer, model2, options
        ).and_return double('plan-dbl-2', cache_key: 'cereal-key-2')

        expect(CacheCrispies).to receive_message_chain(:cache, :fetch_multi).with(
          %w[cereal-key-1 cereal-key-2]
        ).and_yield('cereal-key-1').and_return(name: name1)
          .and_yield('cereal-key-2').and_return(name: name2)

        subject.as_json
      end
    end
  end
end
