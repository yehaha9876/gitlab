# frozen_string_literal: true

require 'spec_helper'

describe Namespace do
  context 'actual_plan_name matchers' do
    described_class::PLANS.each do |namespace_plan|
      case_name = lambda { |plan_name| "like a #{plan_name} plan" }

      def match_plan(plan_name, namespace_plan = plan_name)
        plan = Plan.new(name: plan_name)
        plan.save!
        described_class.new(plan: plan).send("#{namespace_plan}_plan?")
      end

      describe "#{namespace_plan}_plan?" do
        context "for a #{namespace_plan} plan" do
          subject { match_plan(namespace_plan) }
          it { is_expected.to eq(true) }
        end

        context "for a plan that isn't #{namespace_plan}" do
          where(case_names: case_name, plan_name: described_class::PLANS - [namespace_plan])

          with_them do
            subject { match_plan(plan_name, namespace_plan) }
            it { is_expected.to eq(false) }
          end
        end
      end
    end
  end
end
