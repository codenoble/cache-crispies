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
    serialize :name

    def self.key
      'cereal'
    end
  end

  let(:cereal_names) { ['Count Chocula', 'Eyeholes'] }
  let(:collection) { cereal_names.map { |name| Cereal.new(name: name) } }

  subject { CerealController.new }

  before do
    allow_any_instance_of(
      CacheCrispies::Plan
    ).to receive(:etag).and_return 'test-etag'
    allow(subject).to receive_message_chain(:response, :weak_etag=).with 'test-etag'
  end

  describe '#cache_render' do
    it 'renders a json collection' do
      expect(subject).to receive(:render).with(
        json: {
          cereals: cereal_names.map { |name| { name: name } }
        }.to_json
      )

      subject.cache_render CerealSerializerForController, collection
    end

    it 'renders a single json object' do
      expect(subject).to receive(:render).with(
        json: { cereal: { name: cereal_names.first } }.to_json
      )

      subject.cache_render CerealSerializerForController, collection.first
    end

    context 'with a status: option' do
      it 'passes the status option to the Rails render call' do
        expect(subject).to receive(:render).with(
          json: { cereal: { name: cereal_names.first } }.to_json,
          status: 418
        )

        subject.cache_render(
          CerealSerializerForController,
          collection.first,
          status: 418
        )
      end
    end
  end
end
