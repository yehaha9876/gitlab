module EE
  module GeoHelper
    def enable_disable_node_button(node)
      if node.enabled?
        link_to disable_admin_geo_node_path(node), method: :post, title: 'Node is enabled', class: 'has-tooltip btn btn-warning btn-sm prepend-left-10' do
          icon 'power-off', text: 'Disable Node'
        end
      else
        link_to enable_admin_geo_node_path(node), method: :post, title: 'Node is disabled', class: 'has-tooltip btn btn-success btn-sm prepend-left-10' do
          icon 'power-off', text: 'Enable Node'
        end
      end
    end

    def node_status_icon(node)
      if node.enabled?
        icon 'circle', class: 'node-status-enabled'
      else
        icon 'circle', class: 'node-status-disabled'
      end
    end
  end
end
