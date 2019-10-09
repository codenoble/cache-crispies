require 'spec_helper'

describe CacheCrispies::Memoizer do
  describe '#fetch' do
    it 'only calls the block once per key' do
      expect { |block| subject.fetch 1, &block }.to yield_with_no_args
      expect { |block| subject.fetch 1, &block }.to_not yield_with_no_args
      expect { |block| subject.fetch 2, &block }.to yield_with_no_args
    end

    it "returns the block's initial cached value" do
      block = -> {
        @num ||= 0
        @num += 1
      }

      expect(subject.fetch(:a, &block)).to eq 1
      expect(subject.fetch(:a, &block)).to eq 1
      expect(subject.fetch(:b, &block)).to eq 2
    end
  end
end