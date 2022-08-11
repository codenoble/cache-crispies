require 'spec_helper'
require 'ostruct'

describe CacheCrispies::Base do
  class CaloriesSerializer < CacheCrispies::Base
    serialize :calories
  end

  class NutritionSerializer < CaloriesSerializer
    serialize :fat,
              :carbohydrates,
              :sodium,
              :protein
  end

  class CacheCrispiesTestSerializer < CacheCrispies::Base
    serialize :id, :company, to: String

    show_if -> { true } do
      show_if -> { true } do
        show_if :visible? do
          serialize :name, from: :brand
        end
      end
    end

    nest_in :nested do
      nest_in :nested_again do
        serialize :deeply_nested do |model, _opts|
          model.deeply_nested.to_s.upcase
        end
      end
    end

    serialize :nutrition_info, with: NutritionSerializer

    serialize :organic, to: :bool
    serialize :parent_company, through: :legal

    def id
      model.id.to_s
    end

    def visible?
      true
    end
  end

  let(:model) do
    OpenStruct.new(
      id: 42,
      brand: 'Cookie Crisp',
      company: 'General Mills',
      deeply_nested: true,
      nutrition_info: OpenStruct.new(calories: 1_000, fat: 20, carbohydrates: 60, sodium: 30, protein: 10),
      organic: 'true',
      legal: OpenStruct.new(parent_company: 'Disney probably')
    )
  end

  let(:serializer) { CacheCrispiesTestSerializer }
  let(:instance) { serializer.new(model) }
  subject { instance }

  describe '#as_json' do
    it 'serializes to a hash' do
      expect(subject.as_json).to eq(
        id: '42',
        name: 'Cookie Crisp',
        company: 'General Mills',
        nested: {
          nested_again: {
            deeply_nested: 'TRUE'
          }
        },
        nutrition_info: {
          calories: 1000,
          fat: 20,
          carbohydrates: 60,
          sodium: 30,
          protein: 10
        },
        organic: true,
        parent_company: 'Disney probably'
      )
    end

    context 'when nutrition_info is nil' do
      before { model.nutrition_info = nil }

      it 'serializes to a hash' do
        expect(subject.as_json).to eq(
          id: '42',
          name: 'Cookie Crisp',
          company: 'General Mills',
          nested: {
            nested_again: {
              deeply_nested: 'TRUE'
            }
          },
          nutrition_info: nil,
          organic: true,
          parent_company: 'Disney probably'
        )
      end
    end
  end

  describe '.key' do
    it 'underscores the demodulized class name by default' do
      expect(serializer.key).to eq :cache_crispies_test
    end

    context 'with a custom key' do
      after { serializer.remove_instance_variable :@key }

      it 'sets and returns a custom key' do
        expect {
          serializer.key 'custom_key'
        }.to change { serializer.key }.from(:cache_crispies_test).to :custom_key
      end

      it 'sets and returns a nil key' do
        expect {
          serializer.key nil
        }.to change { serializer.key }.from(:cache_crispies_test).to nil
      end
    end
  end

  describe '.collection_key' do
    it 'pluralizes the #key by default' do
      expect(serializer.collection_key).to eq :cache_crispies_tests
    end

    context 'with a custom key' do
      after { serializer.remove_instance_variable :@collection_key }

      it 'sets and returns a custom key' do
        expect {
          serializer.collection_key 'custom_key'
        }.to change {
          serializer.collection_key
        }.from(:cache_crispies_tests).to :custom_key
      end

      it 'sets and returns a nil key' do
        expect {
          serializer.collection_key nil
        }.to change {
          serializer.collection_key
        }.from(:cache_crispies_tests).to nil
      end
    end
  end

  describe '.do_caching' do
    it 'is false by default' do
      expect(serializer.do_caching).to be false
    end

    context 'when called with an argument' do
      after { serializer.remove_instance_variable :@do_caching }

      it 'sets and returns a value' do
        expect {
          serializer.do_caching true
        }.to change {
          serializer.do_caching
        }.from(false).to true
      end
    end
  end

  describe '.cache_key_addons' do
    it 'returns an empty array by default' do
      expect(serializer.cache_key_addons).to eq []
    end

    context 'when given a block' do
      it 'stores the block for later execution' do
        serializer.cache_key_addons { |opts| opts[:username].downcase }
        expect(
          serializer.cache_key_addons(username: 'CapnCrunch')
        ).to eq ['capncrunch']
      end

      it 'returns nil' do
        expect(serializer.cache_key_addons { |_opts| }).to be nil
      end
    end
  end

  describe '.dependency_key' do
    it 'returns nil by default' do
      expect(serializer.dependency_key).to be nil
    end

    context 'after being set' do
      let(:key) { SecureRandom.hex }
      before { serializer.dependency_key key }

      it 'returns the set value' do
        expect(serializer.dependency_key).to be key
      end
    end
  end

  describe '.cache_key_base' do
    let(:nested_serializer_digest) { 'nutrition-serializer-digest' }
    let(:serializer_file_path) {
      File.expand_path('../fixtures/test_serializer.rb', __dir__)
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
      expect(serializer.cache_key_base).to include serializer.to_s
    end

    it "includes a digest of the serializer class file's contents" do
      expect(serializer.cache_key_base).to include serializer_file_digest
    end

    it "includes a digest of the nested serializer class file's contents" do
      expect(serializer.cache_key_base).to include nested_serializer_digest
    end

    it 'correctly formats the key' do
      expect(serializer.cache_key_base).to eq(
        "#{serializer}-#{serializer_file_digest}+#{nested_serializer_digest}"
      )
    end
  end

  describe '.attributes' do
    subject { instance.class.attributes }

    it 'contains all the attributes' do
      expect(subject.length).to eq 7
    end

    it 'preserves the attribute order' do
      expect(subject.map(&:key)).to eq(
        %i[id company name deeply_nested nutrition_info organic parent_company]
      )
    end

    it 'contains the correct attribute values' do
      expect(subject[0].method_name).to eq :id
      expect(subject[0].key).to eq :id
      expect(subject[0].serializer).to be nil
      expect(subject[0].through).to be nil
      expect(subject[0].coerce_to).to be String
      expect(subject[0].nesting).to eq []
      expect(subject[0].conditions).to eq []
      expect(subject[0].block).to be nil

      expect(subject[1].method_name).to eq :company
      expect(subject[1].key).to eq :company
      expect(subject[1].serializer).to be nil
      expect(subject[1].through).to be nil
      expect(subject[1].coerce_to).to be String
      expect(subject[1].nesting).to eq []
      expect(subject[1].conditions).to eq []
      expect(subject[1].block).to be nil

      expect(subject[2].method_name).to eq :brand
      expect(subject[2].key).to eq :name
      expect(subject[2].serializer).to be nil
      expect(subject[2].through).to be nil
      expect(subject[2].coerce_to).to be nil
      expect(subject[2].nesting).to eq []
      expect(subject[2].conditions.length).to be 3
      expect(subject[2].block).to be nil

      expect(subject[3].method_name).to eq :deeply_nested
      expect(subject[3].key).to eq :deeply_nested
      expect(subject[3].serializer).to be nil
      expect(subject[3].through).to be nil
      expect(subject[3].coerce_to).to be nil
      expect(subject[3].nesting).to eq %i[nested nested_again]
      expect(subject[3].conditions).to eq []
      expect(subject[3].block).to be_a_kind_of Proc

      expect(subject[4].method_name).to eq :nutrition_info
      expect(subject[4].key).to eq :nutrition_info
      expect(subject[4].serializer).to be NutritionSerializer
      expect(subject[4].through).to be nil
      expect(subject[4].coerce_to).to be nil
      expect(subject[4].nesting).to eq []
      expect(subject[4].conditions).to eq []
      expect(subject[4].block).to be nil

      expect(subject[5].method_name).to eq :organic
      expect(subject[5].key).to eq :organic
      expect(subject[5].serializer).to be nil
      expect(subject[5].through).to be nil
      expect(subject[5].coerce_to).to be :bool
      expect(subject[5].nesting).to eq []
      expect(subject[5].conditions).to eq []
      expect(subject[5].block).to be nil

      expect(subject[6].method_name).to eq :parent_company
      expect(subject[6].key).to eq :parent_company
      expect(subject[6].serializer).to be nil
      expect(subject[6].through).to be :legal
      expect(subject[6].coerce_to).to be nil
      expect(subject[6].nesting).to eq []
      expect(subject[6].conditions).to eq []
      expect(subject[6].block).to be nil
    end
  end
end
