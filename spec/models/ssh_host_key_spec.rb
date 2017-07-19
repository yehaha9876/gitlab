require 'spec_helper'

describe SshHostKey do
  include ReactiveCachingHelpers

  def stub_ssh_keyscan(args, status: true, stdout: "", stderr: "")
    stdin = StringIO.new
    stdout = double(:stdout, read: stdout)
    stderr = double(:stderr, read: stderr)
    wait_thr = double(:wait_thr, value: double(success?: status))

    expect(Open3).to receive(:popen3).with({}, 'ssh-keyscan', *args).and_yield(stdin, stdout, stderr, wait_thr)

    stdin
  end

  subject(:ssh_host_key) { described_class.new(project_id: 1, url: 'ssh://example.com:2222') }

  describe '#calculate_reactive_cache' do
    subject(:cache) { ssh_host_key.calculate_reactive_cache }

    it 'writes the hostname to STDIN' do
      stdin = stub_ssh_keyscan(%w[-T 5 -p 2222 -f-])

      cache

      expect(stdin.string).to eq("example.com\n")
    end

    context 'successful key scan' do
      it 'stores the cleaned known_hosts data' do
        stub_ssh_keyscan(%w[-T 5 -p 2222 -f-], stdout: "KEY 1\nKEY 1\n\n# comment\nKEY 2\n")

        is_expected.to eq(known_hosts: "KEY 1\nKEY 2\n")
      end
    end

    context 'failed key scan (exit code 1)' do
      it 'returns a generic error' do
        stub_ssh_keyscan(%w[-T 5 -p 2222 -f-], stdout: 'blarg', status: false)

        is_expected.to eq(error: 'Failed to detect SSH host keys')
      end
    end

    context 'failed key scan (exit code 0)' do
      it 'returns a generic error' do
        stub_ssh_keyscan(%w[-T 5 -p 2222 -f-], stderr: 'Unknown host')

        is_expected.to eq(error: 'Failed to detect SSH host keys')
      end
    end
  end
end
