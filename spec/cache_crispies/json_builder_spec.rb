require 'spec_helper'

describe CacheCrispies::JsonBuilder do
  # These example serializers are meant to show a variety of options,
  # configurations, and data types in order to really put the HashBuilder class
  # through the ringer.
  class ConstituentSerializer < CacheCrispies::Base
    serialize :name
  end

  class AllergenSerializer < CacheCrispies::Base
    serialize :name
  end

  class BuzzwordSerializer < CacheCrispies::Base
    serialize :tagline, :small_print

    def tagline
      "#{model.tagline}#{options[:footnote_marker]}"
    end

    def small_print
      "#{options[:footnote_marker]}this doesn't mean jack-squat"
    end
  end

  class CerealSerializerForJsonBuilder < CacheCrispies::Base
    serialize :uid, from: :id, to: String
    serialize :name, :company
    merge :itself, with: BuzzwordSerializer

    nest_in :about do
      nest_in :nutritional_information do
        serialize :calories
        serialize :ingredients, with: ConstituentSerializer

        serialize :allergies, with: AllergenSerializer, optional: true
      end
    end

    show_if ->(_model, options) { options[:be_trendy] } do
      nest_in :health do
        serialize :organic

        show_if ->(model) { model.organic } do
          serialize :certification
        end
      end
    end

    def certification
      'Totally Not A Scam Certifiers Inc'
    end
  end

  let(:organic) { false }
  let(:ingredients) {
    [
      OpenStruct.new(name: 'Sugar'),
      OpenStruct.new(name: 'Other Kind of Sugar')
    ]
  }
  let(:allergies) {
    [
      OpenStruct.new(name: 'Peanuts'),
      OpenStruct.new(name: 'Lactose')
    ]
  }
  let(:model) {
    OpenStruct.new(
      id: 42,
      name: 'Lucky Charms',
      company: 'General Mills',
      calories: 1_000,
      organic: organic,
      tagline: "Part of a balanced breakfast",
      ingredients: ingredients,
      allergies: allergies
    )
  }
  let(:options) { { footnote_marker: '*' } }
  let(:serializer) { CerealSerializerForJsonBuilder.new(model, options) }
  let(:json_writer) { Oj::StringWriter.new(mode: :rails) }
  subject { described_class.new(serializer) }

  describe '#call' do
    let(:recovered_hash) { Oj.compat_load(subject.call(json_writer).to_s, symbol_keys: true) }

    it 'correctly renders the hash' do
      expect(recovered_hash).to eq ({
        uid: '42',
        name: 'Lucky Charms',
        company: 'General Mills',
        tagline: 'Part of a balanced breakfast*',
        small_print: "*this doesn't mean jack-squat",
        about: {
          nutritional_information: {
            calories: 1000,
            ingredients: [
              { name: 'Sugar' },
              { name: 'Other Kind of Sugar' },
            ]
          }
        },
        health: {}
      })
    end

    context 'when the outer show_if is true' do
      let(:options) { { footnote_marker: '†', be_trendy: true } }

      it 'builds values wrapped in the outer if' do
        expect(recovered_hash).to eq ({
          uid: '42',
          name: 'Lucky Charms',
          company: 'General Mills',
          tagline: 'Part of a balanced breakfast†',
          small_print: "†this doesn't mean jack-squat",
          about: {
            nutritional_information: {
              calories: 1000,
              ingredients: [
                { name: 'Sugar' },
                { name: 'Other Kind of Sugar' },
              ]
            }
          },
          health: {
            organic: false
          }
        })
      end

      context 'when the inner show_if is true' do
        let(:organic) { true }

        it 'builds values wrapped in the outer and inner if' do
          expect(recovered_hash).to eq ({
            uid: '42',
            name: 'Lucky Charms',
            company: 'General Mills',
            tagline: 'Part of a balanced breakfast†',
            small_print: "†this doesn't mean jack-squat",
            about: {
              nutritional_information: {
                calories: 1000,
                ingredients: [
                  { name: 'Sugar' },
                  { name: 'Other Kind of Sugar' },
                ]
              }
            },
            health: {
              organic: true,
              certification: 'Totally Not A Scam Certifiers Inc'
            }
          })
        end
      end
    end

    context 'when allergies are included' do
      let(:options) { { footnote_marker: '*', include: :allergies } }

      it 'includes the allergies' do
        expect(recovered_hash).to eq ({
          uid: '42',
          name: 'Lucky Charms',
          company: 'General Mills',
          tagline: 'Part of a balanced breakfast*',
          small_print: "*this doesn't mean jack-squat",
          about: {
            nutritional_information: {
              calories: 1000,
              ingredients: [
                { name: 'Sugar' },
                { name: 'Other Kind of Sugar' },
              ],
              allergies: [
                { name: 'Peanuts' },
                { name: 'Lactose' },
              ]
            }
          },
          health: {}
        })
      end
    end

    context 'when everything is included' do
      let(:options) { { footnote_marker: '*', include: '*' } }

      it 'includes the allergies' do
        expect(recovered_hash).to eq ({
          uid: '42',
          name: 'Lucky Charms',
          company: 'General Mills',
          tagline: 'Part of a balanced breakfast*',
          small_print: "*this doesn't mean jack-squat",
          about: {
            nutritional_information: {
              calories: 1000,
              ingredients: [
                { name: 'Sugar' },
                { name: 'Other Kind of Sugar' },
              ],
              allergies: [
                { name: 'Peanuts' },
                { name: 'Lactose' },
              ]
            }
          },
          health: {}
        })
      end
    end
  end
end
