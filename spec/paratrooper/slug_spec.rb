require 'spec_helper'
require 'paratrooper/configuration'
require 'paratrooper/slug'

describe Paratrooper::Slug do
  describe "slug_id_to_deploy" do
    let(:slug_id) { 'some-slug-id' }

    it "returns configured slug_id" do
      config = instance_double(Paratrooper::Configuration,
        slug_id: slug_id
      )
      slug = described_class.new(config)

      expect(slug.slug_id_to_deploy).to eq(slug_id)
    end

    it "returns slug_id based on configured slug_app_name" do
      app_name = 'some-app-name'
      config = instance_double(Paratrooper::Configuration,
        slug_app_name: app_name, slug_id: nil
      )
      slug = described_class.new(config)
      expect(slug).to receive(:deployed_slug).with(app_name).and_return(slug_id)

      expect(slug.slug_id_to_deploy).to eq(slug_id)

    end

    it "returns unknown slug id" do
      config = instance_double(Paratrooper::Configuration,
        slug_app_name: nil, slug_id: nil
      )
      slug = described_class.new(config)

      expect(slug.slug_id_to_deploy).to eq('UNKNOWN SLUG ID')
    end
  end
end
