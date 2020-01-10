require 'spec_helper'
require 'active_model'
require 'action_controller'

describe CacheCrispies::Controller do
  class Cereal
    include ActiveModel::Model
    attr_accessor :name
  end

  class CerealController < ActionController::Base
    include CacheCrispies::Controller
  end

  class CerealSerializerForController < CacheCrispies::Base
    key 'cereal'
    serialize :name
  end

  let(:cereal_names) { ['Count Chocula', 'Eyeholes'] }
  let(:collection) { cereal_names.map { |name| Cereal.new(name: name) } }

  subject { CerealController.new }

  describe '#cache_render' do
    let(:etags) { false }
    let(:single_hash) { { cereal: { name: cereal_names.first } } }
    let(:single_json) { single_hash.to_json }
    let(:collection_json) {
      { cereals: cereal_names.map { |name| { name: name } } }.to_json
    }

    before do
      expect(
        CacheCrispies
      ).to receive_message_chain(:config, :etags?).and_return etags
    end

    context 'with etags disabled' do
      it 'does not set etags' do
        expect(subject).to receive(:render).with json: collection_json
        response_double = double
        allow(subject).to receive(:response).and_return response_double
        expect(response_double).to_not receive(:weak_etag=)

        subject.cache_render CerealSerializerForController, collection
      end
    end

    context 'with etags enabled' do
      let(:etags) { true }

      it 'sets etags' do
        expect(subject).to receive(:render).with json: collection_json
        expect_any_instance_of(
          CacheCrispies::Plan
        ).to receive(:etag).and_return 'test-etag'
        expect(subject).to receive_message_chain(:response, :weak_etag=).with 'test-etag'

        subject.cache_render CerealSerializerForController, collection
      end
    end

    it 'renders a json collection' do
      expect(subject).to receive(:render).with json: collection_json

      subject.cache_render CerealSerializerForController, collection
    end

    it 'renders a single json object' do
      expect(subject).to receive(:render).with json: single_json

      subject.cache_render CerealSerializerForController, collection.first
    end

    context 'with a status: option' do
      it 'passes the status option to the Rails render call' do
        expect(subject).to receive(:render).with(
          json: single_json,
          status: 418
        )

        subject.cache_render(
          CerealSerializerForController,
          collection.first,
          status: 418
        )
      end
    end

    context 'with a meta: option' do
      it 'adds a meta data hash to the JSON' do
        expect(subject).to receive(:render).with(
          json: single_hash.merge(meta: { page: 42 }).to_json
        )

        subject.cache_render(
          CerealSerializerForController,
          collection.first,
          meta: { page: 42 }
        )
      end
    end

    context 'with a meta_key: option' do
      it 'adds a meta data hash to the JSON with the provided key' do
        expect(subject).to receive(:render).with(
          json: single_hash.merge(test_meta_data: { page: 42 }).to_json
        )

        subject.cache_render(
          CerealSerializerForController,
          collection.first,
          meta: { page: 42 },
          meta_key: :test_meta_data
        )
      end
    end
  end
end
