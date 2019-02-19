# frozen_string_literal: true

require 'spec_helper'

describe ProjectCiCdSetting do
  describe 'default_value_for' do
    it 'has false by default' do
      expect(described_class.new.merge_pipelines_enabled).to be_falsy
    end
  end

  describe '.available?' do
    before do
      described_class.reset_column_information
    end

    it 'returns true' do
      expect(described_class).to be_available
    end

    it 'memoizes the schema version' do
      expect(ActiveRecord::Migrator)
        .to receive(:current_version)
        .and_call_original
        .once

      2.times { described_class.available? }
    end
  end
end
