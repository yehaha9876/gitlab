require 'spec_helper'

describe Gitlab::GithubImport::Client do
  describe '#parallel?' do
    it 'returns true when the client is running in parallel mode' do
      client = described_class.new('foo', parallel: true)

      expect(client).to be_parallel
    end

    it 'returns false when the client is running in sequential mode' do
      client = described_class.new('foo', parallel: false)

      expect(client).not_to be_parallel
    end
  end

  describe '#user' do
    it 'returns the details for the given username' do
      client = described_class.new('foo')

      expect(client.octokit).to receive(:user).with('foo')
      expect(client).to receive(:with_rate_limit).and_yield

      client.user('foo')
    end
  end

  describe '#repository' do
    it 'returns the details of a repository' do
      client = described_class.new('foo')

      expect(client.octokit).to receive(:repo).with('foo/bar')
      expect(client).to receive(:with_rate_limit).and_yield

      client.repository('foo/bar')
    end
  end

  describe '#labels' do
    it 'returns the labels' do
      client = described_class.new('foo')

      expect(client)
        .to receive(:each_object)
        .with(:labels, 'foo/bar')

      client.labels('foo/bar')
    end
  end

  describe '#milestones' do
    it 'returns the milestones' do
      client = described_class.new('foo')

      expect(client)
        .to receive(:each_object)
        .with(:milestones, 'foo/bar')

      client.milestones('foo/bar')
    end
  end

  describe '#releases' do
    it 'returns the releases' do
      client = described_class.new('foo')

      expect(client)
        .to receive(:each_object)
        .with(:releases, 'foo/bar')

      client.releases('foo/bar')
    end
  end

  describe '#each_page' do
    let(:client) { described_class.new('foo') }
    let(:object1) { double(:object1) }
    let(:object2) { double(:object2) }

    before do
      allow(client)
        .to receive(:with_rate_limit)
        .and_yield

      allow(client.octokit)
        .to receive(:public_send)
        .and_return([object1])

      response = double(:response, data: [object2], rels: { next: nil })
      next_page = double(:next_page, get: response)

      allow(client.octokit)
        .to receive(:last_response)
        .and_return(double(:last_response, rels: { next: next_page }))
    end

    context 'without a block' do
      it 'returns an Enumerator' do
        expect(client.each_page(:foo)).to be_an_instance_of(Enumerator)
      end

      it 'the returned Enumerator returns Page objects' do
        enum = client.each_page(:foo)

        page1 = enum.next
        page2 = enum.next

        expect(page1).to be_an_instance_of(described_class::Page)
        expect(page2).to be_an_instance_of(described_class::Page)

        expect(page1.objects).to eq([object1])
        expect(page1.number).to eq(1)

        expect(page2.objects).to eq([object2])
        expect(page2.number).to eq(2)
      end
    end

    context 'with a block' do
      it 'yields every retrieved page to the supplied block' do
        pages = []

        client.each_page(:foo) { |page| pages << page }

        expect(pages[0]).to be_an_instance_of(described_class::Page)
        expect(pages[1]).to be_an_instance_of(described_class::Page)

        expect(pages[0].objects).to eq([object1])
        expect(pages[0].number).to eq(1)

        expect(pages[1].objects).to eq([object2])
        expect(pages[1].number).to eq(2)
      end

      it 'starts at the given page' do
        pages = []

        client.each_page(:foo, page: 2) { |page| pages << page }

        expect(pages[0].number).to eq(2)
        expect(pages[1].number).to eq(3)
      end
    end
  end

  describe '#with_rate_limit' do
    let(:client) { described_class.new('foo') }

    it 'yields the supplied block when enough requests remain' do
      expect(client).to receive(:requests_remaining?).and_return(true)

      expect { |b| client.with_rate_limit(&b) }.to yield_control
    end

    it 'waits before yielding if not enough requests remain' do
      expect(client).to receive(:requests_remaining?).and_return(false)
      expect(client).to receive(:raise_or_wait_for_rate_limit)

      expect { |b| client.with_rate_limit(&b) }.to yield_control
    end

    it 'waits and retries the operation if all requests were consumed in the supplied block' do
      retries = 0

      expect(client).to receive(:requests_remaining?).and_return(true)
      expect(client).to receive(:raise_or_wait_for_rate_limit)

      client.with_rate_limit do
        if retries.zero?
          retries += 1
          raise(Octokit::TooManyRequests)
        end
      end

      expect(retries).to eq(1)
    end

    it 'increments the request count counter' do
      expect(client.request_count_counter)
        .to receive(:increment)
        .and_call_original

      expect(client).to receive(:requests_remaining?).and_return(true)

      client.with_rate_limit { }
    end
  end

  describe '#requests_remaining?' do
    let(:client) { described_class.new('foo') }

    it 'returns true if enough requests remain' do
      expect(client).to receive(:remaining_requests).and_return(9000)

      expect(client.requests_remaining?).to eq(true)
    end

    it 'returns false if not enough requests remain' do
      expect(client).to receive(:remaining_requests).and_return(1)

      expect(client.requests_remaining?).to eq(false)
    end
  end

  describe '#raise_or_wait_for_rate_limit' do
    it 'raises RateLimitError when running in parallel mode' do
      client = described_class.new('foo', parallel: true)

      expect { client.raise_or_wait_for_rate_limit }
        .to raise_error(Gitlab::GithubImport::RateLimitError)
    end

    it 'sleeps when running in sequential mode' do
      client = described_class.new('foo', parallel: false)

      expect(client).to receive(:rate_limit_resets_in).and_return(1)
      expect(client).to receive(:sleep).with(1)

      client.raise_or_wait_for_rate_limit
    end

    it 'increments the rate limit counter' do
      client = described_class.new('foo', parallel: false)

      expect(client)
        .to receive(:rate_limit_resets_in)
        .and_return(1)

      expect(client)
        .to receive(:sleep)
        .with(1)

      expect(client.rate_limit_counter)
        .to receive(:increment)
        .and_call_original

      client.raise_or_wait_for_rate_limit
    end
  end

  describe '#remaining_requests' do
    it 'returns the number of remaining requests' do
      client = described_class.new('foo')
      rate_limit = double(remaining: 1)

      expect(client.octokit).to receive(:rate_limit).and_return(rate_limit)
      expect(client.remaining_requests).to eq(1)
    end
  end

  describe '#rate_limit_resets_in' do
    it 'returns the number of seconds after which the rate limit is reset' do
      client = described_class.new('foo')
      rate_limit = double(resets_in: 1)

      expect(client.octokit).to receive(:rate_limit).and_return(rate_limit)

      expect(client.rate_limit_resets_in).to eq(6)
    end
  end

  describe '#method_missing' do
    it 'delegates missing methods to the request method' do
      client = described_class.new('foo')

      expect(client).to receive(:milestones).with(state: 'all')

      client.milestones(state: 'all')
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true for methods supported by Octokit' do
      client = described_class.new('foo')

      expect(client.respond_to?(:milestones)).to eq(true)
    end

    it 'returns false for methods not supported by Octokit' do
      client = described_class.new('foo')

      expect(client.respond_to?(:kittens)).to eq(false)
    end
  end
end
