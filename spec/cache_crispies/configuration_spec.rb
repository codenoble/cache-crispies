require 'spec_helper'

describe CacheCrispies::Configuration do
  describe '#cache_store' do
    context 'when Rails.cache is defined' do
      let(:cache_double) { double }
      before { expect(Rails).to receive(:cache).and_return cache_double }

      it 'is Rails.cache by default' do
        expect(subject.cache_store).to be cache_double
      end
    end

    context 'when Rails.cache is nil' do
      before { expect(Rails).to receive(:cache).and_return nil }

      it 'is NullStore by default' do
        expect(subject.cache_store).to be_kind_of ActiveSupport::Cache::NullStore
      end
    end

    it 'can be changed' do
      cache_store = ActiveSupport::Cache::NullStore.new

      expect {
        subject.cache_store = cache_store
      }.to change { subject.cache_store }.to cache_store
    end
  end

  describe '#etags' do
    it 'is false by default' do
      expect(subject.etags).to be false
    end

    it 'can be changed' do
      expect {
        subject.etags = true
      }.to change { subject.etags }.to true
    end
  end
end
