# frozen_string_literal: true

module QA
  module EE
    module Factory
      module Resource
        class Epic < QA::Factory::Base
          attr_accessor :title

          dependency QA::Factory::Resource::Group, as: :group

          def fabricate!
            group.visit!

            QA::EE::Page::Group::Menu.perform { |menu| menu.go_to_group_epics }

            QA::EE::Page::Group::Epic::Index.perform do |page|
              page.click_new_epic
              page.set_title(@title)
              page.create_new_epic
              page.wait(time: 1) do
                page.has_text?(@title)
              end
            end
          end
        end
      end
    end
  end
end