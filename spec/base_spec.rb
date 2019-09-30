require 'spec_helper'
require 'ostruct'

describe CacheCrispies::Base do
  class NutritionSerializer < CacheCrispies::Base
    serialize :calories
  end

  class CacheCrispiesTestSerializer < CacheCrispies::Base
    serialize :id, :company, to: String

    show_if -> { true } do
      show_if -> { true } do
        show_if -> { true } do
          serialize :name, from: :brand
        end
      end
    end

    nest_in :nested do
      nest_in :nested_again do
        serialize :deeply_nested
      end
    end

    serialize :nutrition_info, with: NutritionSerializer

    serialize :organic, to: :bool

    def id
      model.id.to_s
    end
  end

  let(:model) do
    OpenStruct.new(
      id: 42,
      brand: 'Cookie Crisp',
      company: 'General Mills',
      deeply_nested: true,
      nutrition_info: OpenStruct.new(calories: 1_000),
      organic: 'true'
      )
  end

  let(:instance) { CacheCrispiesTestSerializer.new(model) }
  subject { instance }

  describe '#as_json' do
    it 'serializes to a hash' do
      expect(subject.as_json).to eq(
        id: '42',
        name: 'Cookie Crisp',
        company: 'General Mills',
        nested: {
          nested_again: {
            deeply_nested: true
          }
        },
        nutrition_info: {
          calories: 1000
        },
        organic: true
      )
    end
  end

  describe '.key' do
    it 'underscores the demodulized class name' do
      expect(subject.class.key).to eq :cache_crispies_test
    end
  end

  describe '.dependency_key' do
    it 'returns nil by default' do
      expect(subject.class.dependency_key).to be nil
    end

    context 'after being set' do
      let(:key) { SecureRandom.hex }
      before { subject.class.dependency_key key }

      it 'returns the set value' do
        expect(subject.class.dependency_key).to be key
      end
    end
  end

  describe '.collection_key' do
    it 'pluralizes the #key' do
      expect(subject.class.collection_key).to eq :cache_crispies_tests
    end
  end

  describe '.do_caching?' do
    it 'is false by default' do
      expect(subject.class.do_caching?).to be false
    end
  end

  describe '.cache_key_addons' do
    it 'returns an empty array by default' do
      expect(subject.class.cache_key_addons).to eq []
    end
  end

  describe '.cache_key_base' do
    let(:nested_serializer_digest) { 'nutrition-serializer-digest' }
    let(:serializer_file_path) {
      File.expand_path('fixtures/test_serializer.rb', __dir__)
    }
    let(:serializer_file_digest) {
      Digest::MD5.file(serializer_file_path).to_s
    }

    before do
      allow(NutritionSerializer).to receive(:file_hash).and_return(
        nested_serializer_digest
      )
      allow(Rails).to receive_message_chain(:root, :join).and_return(
        serializer_file_path
      )
    end

    it 'includes the file name' do
      expect(subject.class.cache_key_base).to include subject.class.to_s
    end

    it "includes a digest of the serializer class file's contents" do
      expect(subject.class.cache_key_base).to include serializer_file_digest
    end

    it "includes a digest of the nested serializer class file's contents" do
      expect(subject.class.cache_key_base).to include nested_serializer_digest
    end

    it 'correctly formats the key' do
      expect(subject.class.cache_key_base).to eq(
        "#{subject.class}-#{serializer_file_digest}+#{nested_serializer_digest}"
      )
    end
  end

  describe '.attributes' do
    subject { instance.class.attributes }

    it 'contains all the attributes' do
      expect(subject.length).to eq 6
    end

    it 'preserves the attribute order' do
      expect(subject.map(&:key)).to eq(
        %i[id company name deeply_nested nutrition_info organic]
      )
    end

    it 'contains the correct attribute values' do
      expect(subject[0].method_name).to eq :id
      expect(subject[0].key).to eq :id
      expect(subject[0].serializer).to be nil
      expect(subject[0].coerce_to).to be String
      expect(subject[0].nesting).to eq []
      expect(subject[0].conditions).to eq []

      expect(subject[1].method_name).to eq :company
      expect(subject[1].key).to eq :company
      expect(subject[1].serializer).to be nil
      expect(subject[1].coerce_to).to be String
      expect(subject[1].nesting).to eq []
      expect(subject[1].conditions).to eq []

      expect(subject[2].method_name).to eq :brand
      expect(subject[2].key).to eq :name
      expect(subject[2].serializer).to be nil
      expect(subject[2].coerce_to).to be nil
      expect(subject[2].nesting).to eq []
      expect(subject[2].conditions.length).to be 3

      expect(subject[3].method_name).to eq :deeply_nested
      expect(subject[3].key).to eq :deeply_nested
      expect(subject[3].serializer).to be nil
      expect(subject[3].coerce_to).to be nil
      expect(subject[3].nesting).to eq %i[nested nested_again]
      expect(subject[3].conditions).to eq []

      expect(subject[4].method_name).to eq :nutrition_info
      expect(subject[4].key).to eq :nutrition_info
      expect(subject[4].serializer).to be NutritionSerializer
      expect(subject[4].coerce_to).to be nil
      expect(subject[4].nesting).to eq []
      expect(subject[4].conditions).to eq []

      expect(subject[5].method_name).to eq :organic
      expect(subject[5].key).to eq :organic
      expect(subject[5].serializer).to be nil
      expect(subject[5].coerce_to).to be :bool
      expect(subject[5].nesting).to eq []
      expect(subject[5].conditions).to eq []
    end
  end
end
