require 'spec_helper'

describe CacheCrispies::Plan do
  class CerealSerializerForPlan < CacheCrispies::Base
    key :cereal
    dependency_key :'v1-beta'

    cache_key_addons do |options|
      ['addon1', options[:extra_addon]]
    end

    serialize :name
  end

  let(:serializer) { CerealSerializerForPlan }
  let(:serializer_file_path) {
    File.expand_path('../fixtures/test_serializer.rb', __dir__)
  }
  let(:model_cache_key) { 'model-cache-key' }
  let(:model) { OpenStruct.new(name: 'Sugar Smacks', cache_key: model_cache_key) }
  let(:cacheable) { model }
  let(:options) { {} }
  let(:instance) { described_class.new(serializer, cacheable, **options) }
  subject { instance }

  before do
    allow(Rails).to receive_message_chain(:root, :join).and_return(
      serializer_file_path
    )
  end

  describe '#collection?' do
    context 'when not a collection' do
      let(:cacheable) { Object.new }

      it 'returns false' do
        expect(subject.collection?).to be false
      end

      context 'when the :collection option is true' do
        let(:options) { { collection: true } }

        it 'returns true' do
          expect(subject.collection?).to be true
        end
      end
    end

    context 'when a collection' do
      let(:cacheable) { [Object.new] }

      it 'returns false' do
        expect(subject.collection?).to be true
      end

      context 'when the :collection option is false' do
        let(:options) { { collection: false } }

        it 'returns false' do
          expect(subject.collection?).to be false
        end
      end
    end
  end

  describe '#etag' do
    it 'generates an MD5 digest of the cache_key' do
      expect(subject).to receive(:cache_key).and_return 'foo'
      expect(subject.etag).to eq Digest::MD5::hexdigest('foo')
    end
  end

  describe '#cache_key' do
    let(:options) { { extra_addon: 'addon2' } }

    it 'returns a string' do
      expect(subject.cache_key).to be_a String
    end

    it 'includes the CACHE_KEY_PREFIX' do
      expect(subject.cache_key).to include CacheCrispies::CACHE_KEY_PREFIX
    end

    it "includes the serializer's #cache_key_base" do
      expect(subject.cache_key).to include serializer.cache_key_base
    end

    it "includes the serializer's #dependency_key" do
      expect(subject.cache_key).to include 'v1-beta'
    end

    it "includes the addons_key" do
      expect(subject.cache_key).to include(
        Digest::MD5.hexdigest('addon1|addon2')
      )
    end

    it "includes the cacheable #cache_key" do
      expect(subject.cache_key).to include model_cache_key
    end

    it 'includes the CACHE_KEY_SEPARATOR' do
      expect(subject.cache_key).to include CacheCrispies::CACHE_KEY_SEPARATOR
    end

    it 'generates the key correctly' do
      expect(subject.cache_key).to eq(
        'cache-crispies' \
        "+CerealSerializerForPlan-#{Digest::MD5.file(serializer_file_path)}" \
        '+v1-beta' \
        "+#{Digest::MD5.hexdigest('addon1|addon2')}" \
        '+model-cache-key'
      )
    end

    context 'without addons' do
      it 'generates the key without that section' do
        expect(serializer).to receive(:cache_key_addons).and_return []

        expect(subject.cache_key).to eq(
          'cache-crispies' \
          "+CerealSerializerForPlan-#{Digest::MD5.file(serializer_file_path)}" \
          '+v1-beta' \
          '+model-cache-key'
        )
      end
    end
  end

  describe '#cache' do
    context 'when the plan is not cacheable' do
      it "doesn't cache the results" do
        expect(CacheCrispies).to_not receive(:cache)
        subject.cache {}
      end
    end

    context 'when the plan is not cacheable' do
      it "doesn't cache the results" do
        expect(subject).to receive(:cache?).and_return true
        expect(subject).to receive(:cache_key).and_return 'bar'
        expect(CacheCrispies).to receive_message_chain(:cache, :fetch).with('bar')
        subject.cache {}
      end
    end
  end

  describe '#wrap' do
    let(:json_hash) { { name: 'Kix' } }
    subject { instance.wrap(json_hash) }

    context 'when the serializer has no key' do
      before { expect(serializer).to receive(:key).and_return nil }

      it 'returns the json Hash directly' do
        expect(subject).to be json_hash
      end
    end

    context 'when key is false' do
      let(:options) { { key: false } }

      it 'returns json_hash unchanged' do
        expect(subject).to be json_hash
      end
    end

    context 'with an optional key' do
      let(:options) { { key: :cereal_test } }

      it 'wraps the hash using the provided key option' do
        expect(subject).to eq cereal_test: json_hash
      end
    end

    context "when it's a colleciton" do
      let(:cacheable) { [model] }

      it "wraps the hash in the serializer's colleciton_key" do
        expect(subject).to eq cereals: json_hash
      end
    end

    context "when it's not a collection" do
      it "wraps the hash in the serializer's key" do
        expect(subject).to eq cereal: json_hash
      end
    end
  end
end
