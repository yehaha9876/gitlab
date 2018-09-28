module QA
  module Page
    module Menu
      class Admin < Page::Base
        prepend EE::Page::Menu::Admin

        view 'app/views/layouts/nav/sidebar/_admin.html.haml' do
          element :sidebar
          element :submenu
          element :settings_menu_item
          element :settings_repository_menu_item
        end

        def go_to_settings
          click_link :settings_menu_item
        end

        def go_to_repository_settings
          hover_settings do
            within_submenu do
              click_element :settings_repository_menu_item
            end
          end
        end

        private

        def hover_settings
          within_sidebar do
            find_element(:settings_menu_item).hover

            yield
          end
        end

        def within_sidebar
          within_element(:sidebar) do
            yield
          end
        end

        def within_submenu
          within_element(:submenu) do
            yield
          end
        end
      end
    end
  end
end
