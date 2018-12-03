# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelineEnums do
  describe '.failure_reasons' do
    subject { described_class.failure_reasons }

    it_behaves_like 'Unique enum values'
  end

  describe '.sources' do
    subject { described_class.sources }

    it_behaves_like 'Unique enum values'
  end
end
