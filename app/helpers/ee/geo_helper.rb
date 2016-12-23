module EE
  module GeoHelper
    def enable_disable_node_button(node)
      if node.enabled?
        link_to disable_admin_geo_node_path(node),
                method: :post, class: 'btn btn-warning btn-sm prepend-left-10',
                data: { confirm: 'Disabling a node stops all replication processes, but it will remain accessible. Are you sure?' } do
          icon 'power-off', text: 'Disable Node'
        end
      else
        link_to enable_admin_geo_node_path(node), method: :post, class: 'btn btn-success btn-sm prepend-left-10' do
          icon 'power-off', text: 'Enable Node'
        end
      end
    end

    def node_status_icon(node)
      if node.enabled?
        icon 'circle', class: 'has-tooltip node-status-enabled', title: 'Node is enabled', data: { placement: 'right' }
      else
        icon 'circle', class: 'has-tooltip node-status-disabled', title: 'Node is disabled', data: { placement: 'right' }
      end
    end
  end
end
