# frozen_string_literal: true

require 'spec_helper'

describe GoldTrialUserCalloutsHelper do
  subject { Class.new.extend(described_class) }

  # Compose an array that represents a 2D matrix of
  # boolean types in which every row is unique.
  def build_boolean_matrix(count)
    Array.new(count << 1).fill(Array.new(count)).map.with_index do |y_el, y_i|
      y_el.map.with_index { |x_el, x_i| (y_i >> x_i & 1).zero? }
    end
  end

  describe 'render_dashboard_gold_trial' do
    def execute
      subject.render_dashboard_gold_trial(nil)
    end

    methods = [:show_gold_trial?, :user_default_dashboard?, :has_no_trial_or_gold_plan?]
    valid_conditions = [true, true, true]

    context 'if the callout is not dismissed, there is no gold trial/plan and it is the default dashboard' do
      before do
        allow(subject).to receive(:show_gold_trial?) { valid_conditions[0] }
        allow(subject).to receive(:user_default_dashboard?) { valid_conditions[1] }
        allow(subject).to receive(:has_no_trial_or_gold_plan?) { valid_conditions[2] }
      end

      it do
        expect(subject).to receive(:render_if_exists).with('shared/gold_trial_callout')

        execute
      end
    end

    context 'if conditions are invalid' do
      where(*methods) { build_boolean_matrix(methods.length) - [valid_conditions] }

      with_them do
        before do
          allow(subject).to receive(:show_gold_trial?) { show_gold_trial? }
          allow(subject).to receive(:user_default_dashboard?) { user_default_dashboard? }
          allow(subject).to receive(:has_no_trial_or_gold_plan?) { has_no_trial_or_gold_plan? }
        end

        it do
          expect(subject).not_to receive(:render_if_exists)

          execute
        end
      end
    end
  end

  describe 'render_billings_gold_trial' do
    set(:namespace) { create(:namespace) }

    def execute(namespace)
      subject.render_billings_gold_trial(namespace, nil)
    end

    methods = [:show_gold_trial?, :gold_plan?, :free_plan?]
    valid_conditions = [
      [true, false, true],
      [true, false, false]
    ]

    context 'if conditions are valid' do
      where(*methods) { valid_conditions }

      with_them do
        before do
          allow(subject).to receive(:show_gold_trial?) { show_gold_trial? }
          allow(namespace).to receive(:gold_plan?) { gold_plan? }
          allow(namespace).to receive(:free_plan?) { free_plan? }
        end

        it do
          expect(subject).to receive(:render_if_exists).with('shared/gold_trial_callout', is_dismissable: !free_plan?)

          execute(namespace)
        end
      end
    end

    context 'if conditions are invalid' do
      where(*methods) { build_boolean_matrix(methods.length).reject {|condition| valid_conditions.include? condition} }

      with_them do
        before do
          allow(subject).to receive(:show_gold_trial?) { show_gold_trial? }
          allow(namespace).to receive(:gold_plan?) { gold_plan? }
          allow(namespace).to receive(:free_plan?) { free_plan? }
        end

        it do
          expect(subject).not_to receive(:render_if_exists).with('shared/gold_trial_callout', is_dismissable: !free_plan?)

          execute(namespace)
        end
      end
    end
  end
end
