# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::YamlProcessor do
  describe '#initial_parsing' do
    let(:tag) { ::Ci::Build::WEB_IDE_JOB_TAG }

    it "returns valid if no job has the #{::Ci::Build::WEB_IDE_JOB_TAG} tag" do
      config = YAML.dump({ job1: { script: 'whatever' } })

      expect do
        described_class.new(config)
      end.not_to raise_error
    end

    context "when config has jobs tagged with #{::Ci::Build::WEB_IDE_JOB_TAG}" do
      it 'returns valid if only one job has the tag' do
        config = YAML.dump({ job1: { script: 'whatever', tags: [tag] } })

        expect do
          described_class.new(config)
        end.not_to raise_error
      end

      it 'raises error if more than one job has the tag' do
        config = YAML.dump({ job1: { script: 'whatever', tags: [tag] }, job2: { script: 'whatever', tags: [tag] } })

        expect do
          described_class.new(config)
        end.to raise_error(Gitlab::Ci::YamlProcessor::ValidationError, "Only one job can be configured to run the web ide terminal")
      end
    end
  end
end
