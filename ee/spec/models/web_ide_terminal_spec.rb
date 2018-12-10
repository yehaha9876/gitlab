# frozen_string_literal: true

require 'spec_helper'

describe WebIdeTerminal do
  let(:build) { create(:ci_build) }

  subject { described_class.new(build) }

  before do
    stub_default_url_options(protocol: 'http', host: 'example.com')
  end

  it 'returns the show_path of the build' do
    expect(subject.show_path).to eq("http://example.com/#{build.project.full_path}/ide_terminals/#{build.id}")
  end

  it 'returns the retry_path of the build' do
    expect(subject.retry_path).to eq("http://example.com/#{build.project.full_path}/ide_terminals/#{build.id}/retry")
  end

  it 'returns the cancel_path of the build' do
    expect(subject.cancel_path).to eq("http://example.com/#{build.project.full_path}/ide_terminals/#{build.id}/cancel")
  end

  it 'returns the terminal_path of the build' do
    expect(subject.terminal_path).to eq("http://example.com/#{build.project.full_path}/-/jobs/#{build.id}/terminal.ws")
  end
end
