module Gitlab
  module Ci
    module Status
      module Build
        class ManualWithAutoPlay < Status::Extended
          ###
          # TODO: Those are random values. We have to fix accoding to the UX review
          ###

          ###
          # Core override
          ###
          def text
            s_('CiStatusText|manual with auto play')
          end

          def label
            s_('CiStatusLabel|manual action with auto play')
          end

          def icon
            'soft-unwrap'
          end

          def favicon
            'favicon_status_manual_with_auto_play'
          end

          ###
          # Extension override
          ###
          def illustration
            {
              image: 'illustrations/canceled-job_empty.svg',
              size: 'svg-394',
              title: _('This job requires a manual action with auto play'),
              content: _('auto playyyyyyyyyyyyyy! This job depends on a user to trigger its process. Often they are used to deploy code to production environments')
            }
          end

          def status_tooltip
            @status.status_tooltip + " (auto play) : Executed in #{(subject.build_schedule.execute_in / 1.minute).round}"
          end

          def self.matches?(build, user)
            build.autoplay?
          end
        end
      end
    end
  end
end
