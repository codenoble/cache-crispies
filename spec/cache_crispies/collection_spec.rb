require 'spec_helper'

describe CacheCrispies::Collection do
  class UncacheableCerealSerializerForCollection < CacheCrispies::Base
    serialize :name
  end

  class CacheableCerealSerializerForCollection < CacheCrispies::Base
    serialize :name
    do_caching true
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
          expect(subject.as_json).to eq [{ name: name1 }, { name: name2 }]
        end
      end

      context 'because the serializer is not cacheable' do
        let(:serializer) { UncacheableCerealSerializerForCollection }

        it "doesn't cache the results" do
          expect(CacheCrispies::Plan).to_not receive(:new)
          expect(CacheCrispies).to_not receive :cache
          expect(subject.as_json).to eq [{ name: name1 }, { name: name2 }]
        end
      end
    end

    context 'when it is cacheable' do
      context 'when the collection cache key misses' do
        before do
          allow(CacheCrispies).to receive_message_chain(
            :cache, :fetch
          ).with('cacheable-collection-key').and_yield
        end

        it 'fetches the cache for each object in the collection' do
          expect(CacheCrispies::Plan).to receive(:new).with(
            serializer, model1, **options
          ).and_return double('plan-dbl-1', cache_key: 'cereal-key-1')

          expect(CacheCrispies::Plan).to receive(:new).with(
            serializer, model2, **options
          ).and_return double('plan-dbl-2', cache_key: 'cereal-key-2')

          expect(CacheCrispies).to receive_message_chain(:cache, :read_multi).
            with('cereal-key-1', 'cereal-key-2').and_return({})

          expect(CacheCrispies).to receive_message_chain(
            :cache, :write_multi
          ).with(
            { 'cereal-key-1' => { name: name1 }, 'cereal-key-2' => { name: name2 } }
          )

          subject.as_json
        end
      end

      context 'when the collection cache key does not miss' do
        before do
          allow(CacheCrispies).to receive_message_chain(
            :cache, :fetch
          ).with('cacheable-collection-key').and_yield
        end

        it 'fetches the cache for each object in the collection' do
          expect(CacheCrispies::Plan).to receive(:new).with(
            serializer, model1, **options
          ).and_return double('plan-dbl-1', cache_key: 'cereal-key-1')

          expect(CacheCrispies::Plan).to receive(:new).with(
            serializer, model2, **options
          ).and_return double('plan-dbl-2', cache_key: 'cereal-key-2')

          expect(CacheCrispies).to receive_message_chain(:cache, :read_multi).
            with('cereal-key-1', 'cereal-key-2').
            and_return(
              { 'cereal-key-1' => { name: name1 }, 'cereal-key-2' => { name: name2 } }
            )

          expect(CacheCrispies).to receive_message_chain(
            :cache, :write_multi
          ).with({})

          subject.as_json
        end
      end
    end
  end
end
