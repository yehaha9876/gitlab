# frozen_string_literal: true

require 'spec_helper'

describe IdeTerminalEntity do
  let(:build) { create(:ci_build) }
  let(:entity) { described_class.new(IdeTerminal.new(build)) }

  subject { entity.as_json }

  it { is_expected.to have_key(:id) }
  it { is_expected.to have_key(:status) }
  it { is_expected.to have_key(:show_path) }
  it { is_expected.to have_key(:cancel_path) }
  it { is_expected.to have_key(:retry_path) }
  it { is_expected.to have_key(:terminal_path) }
end
