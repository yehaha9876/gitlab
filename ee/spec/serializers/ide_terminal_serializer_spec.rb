# frozen_string_literal: true

require 'spec_helper'

describe IdeTerminalSerializer do
  let(:build) { create(:ci_build) }

  subject { described_class.new.represent(IdeTerminal.new(build)) }

  it 'represents IdeTerminalEntity entities' do
    expect(described_class.entity_class).to eq(IdeTerminalEntity)
  end

  it 'accepts IdeTerminal as a resource' do
    expect(subject[:id]).to eq build.id
  end

  context 'when resource is a build' do
    subject { described_class.new.represent(build) }

    it 'transforms it into a IdeTerminal resource' do
      expect(IdeTerminal).to receive(:new)

      subject
    end
  end
end
