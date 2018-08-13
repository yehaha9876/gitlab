# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::ClusterRoleBinding do
  let(:name) { 'cluster-role-binding-name' }
  let(:cluster_role_name) { 'cluster-admin' }
  let(:subjects) { [{ kind: 'ServiceAccount', name: 'sa', namespace: 'ns' }] }
  let(:cluster_role_binding) { described_class.new(name, cluster_role_name, subjects) }

  describe '#generate' do
    let(:role_ref) { { apiGroup: 'rbac.authorization.k8s.io', kind: 'ClusterRole', name: cluster_role_name } }
    let(:resource) { ::Kubeclient::Resource.new(metadata: { name: name }, roleRef: role_ref, subjects: subjects) }

    subject { cluster_role_binding.generate }

    it 'should build a Kubeclient Resource' do
      is_expected.to eq(resource)
    end
  end
end
