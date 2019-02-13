# frozen_string_literal: true

module EE
  module MergeRequests
    module MergeBaseService
      extend ::Gitlab::Utils::Override

      override :error_check!
      def error_check!
        check_size_limit
      end

      override :hooks_validation_pass?
      def hooks_validation_pass?(merge_request)
        # handle_merge_error needs this. We should move that to a separate
        # object instead of relying on the order of method calls.
        @merge_request = merge_request # rubocop:disable Gitlab/ModuleWithInstanceVariables

        hooks_error = hooks_validation_error(merge_request)

        return true unless hooks_error

        handle_merge_error(log_message: hooks_error, save_message_on_model: true)

        false
      rescue PushRule::MatchError => e
        handle_merge_error(log_message: e.message, save_message_on_model: true)
        false
      end

      override :hooks_validation_error
      def hooks_validation_error(merge_request)
        return if project.merge_requests_ff_only_enabled
        return unless project.feature_available?(:push_rules)

        push_rule = merge_request.project.push_rule
        return unless push_rule

        if !push_rule.commit_message_allowed?(params[:commit_message])
          "Commit message does not follow the pattern '#{push_rule.commit_message_regex}'"
        elsif push_rule.commit_message_blocked?(params[:commit_message])
          "Commit message contains the forbidden pattern '#{push_rule.commit_message_negative_regex}'"
        elsif !push_rule.author_email_allowed?(current_user.commit_email)
          "Commit author's email '#{current_user.commit_email}' does not follow the pattern '#{push_rule.author_email_regex}'"
        end
      end

      private

      def check_size_limit
        if merge_request.target_project.above_size_limit?
          message = ::Gitlab::RepositorySizeError.new(merge_request.target_project).merge_error

          raise ::MergeRequests::MergeService::MergeError, message
        end
      end
    end
  end
end
