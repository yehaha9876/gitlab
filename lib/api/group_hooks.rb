module API
  class GroupHooks < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers do
      params :project_hook_properties do
        requires :url, type: String, desc: 'The URL to send the request to'
        optional :push_events, type: Boolean, desc: 'Trigger hook on push events'
        optional :issues_events, type: Boolean, desc: 'Trigger hook on issues events'
        optional :merge_requests_events, type: Boolean, desc: 'Trigger hook on merge request events'
        optional :tag_push_events, type: Boolean, desc: 'Trigger hook on tag push events'
        optional :note_events, type: Boolean, desc: 'Trigger hook on note(comment) events'
        optional :build_events, type: Boolean, desc: 'Trigger hook on build events'
        optional :pipeline_events, type: Boolean, desc: 'Trigger hook on pipeline events'
        optional :wiki_events, type: Boolean, desc: 'Trigger hook on wiki events'
        optional :enable_ssl_verification, type: Boolean, desc: 'Do SSL verification when triggering the hook'
        optional :token, type: String, desc: 'Secret token to validate received payloads; this will not be returned in the response'
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups do
      desc 'Get group hooks' do
        success Entities::ProjectHook
      end
      params do
        use :pagination
      end
      get ':id/hooks' do
        group = find_group!(params[:id])
        authorize! :admin_group, group

        present paginate(group.hooks), with: Entities::ProjectHook
      end

      desc 'Get a group hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of a project hook'
      end
      get ':id/hooks/:hook_id' do
        group = find_group!(params[:id])
        authorize! :admin_group, group

        hook = group.hooks.find_by(id: params[:hook_id])
        not_found!('Hook') unless hook

        present hook, with: Entities::ProjectHook
      end

      desc 'Add hook to a group' do
        success Entities::ProjectHook
      end
      params do
        use :project_hook_properties
      end
      post ':id/hooks' do
        group = find_group!(params.delete(:id))
        authorize! :admin_group, group

        hook = group.hooks.new(declared_params(include_missing: false))

        if hook.save
          present hook, with: Entities::ProjectHook
        else
          render_validation_error!(hook)
        end
      end

      desc 'Update an existing group hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the hook to update'
        use :project_hook_properties
      end
      put ':id/hooks/:hook_id' do
        group = find_group!(params.delete(:id))
        authorize! :admin_group, group

        hook = group.hooks.find_by(id: params.delete(:hook_id))
        not_found!('Hook') unless hook

        if hook.update_attributes(declared_params(include_missing: false))
          present hook, with: Entities::ProjectHook
        else
          render_validation_error!(hook)
        end
      end

      desc 'Delete a group hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the hook to delete'
      end
      delete ':id/hooks/:hook_id' do
        group = find_group!(params[:id])
        authorize! :admin_group, group

        hook = group.hooks.find_by(id: params[:hook_id])
        not_found!('Hook') unless hook

        hook.destroy
      end
    end
  end
end
