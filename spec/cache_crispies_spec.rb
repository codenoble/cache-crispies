require 'spec_helper'

describe CacheCrispies do
  after { described_class.config.reset! }

  describe '.configure and .config' do
    it 'allows setting values' do
      expect {
        described_class.configure do |conf|
          conf.etags = true
        end
      }.to change { described_class.config.etags }.from(false).to true
    end
  end

  describe '.cache' do
    it 'delegates to config.cache_store' do
      cache_store = ActiveSupport::Cache::NullStore.new

      expect {
        described_class.configure do |conf|
          conf.cache_store = cache_store
        end
      }.to change { described_class.cache }.to cache_store
    end
  end
end
