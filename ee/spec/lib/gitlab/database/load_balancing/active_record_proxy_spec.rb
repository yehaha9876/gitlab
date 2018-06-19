require 'spec_helper'

describe Gitlab::Database::LoadBalancing::ActiveRecordProxy do
  describe '#connection' do
    it 'returns a connection proxy' do
      dummy = Class.new do
        include Gitlab::Database::LoadBalancing::ActiveRecordProxy
      end

      proxy = double(:proxy)

      expect(Gitlab::Database::LoadBalancing).to receive(:proxy)
        .and_return(proxy)

      expect(dummy.new.connection).to eq(proxy)
    end

    it 'does not return a load balancing proxy' do
      dummy = Class.new do
        extend Gitlab::Database::LoadBalancing::IgnoreLoadBalancing
        include Gitlab::Database::LoadBalancing::ActiveRecordProxy

        def connection
          true
        end
      end

      expect(Gitlab::Database::LoadBalancing).not_to receive(:proxy)

      expect(dummy.new.connection).to be_truthy
    end
  end
end
