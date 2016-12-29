require 'spec_helper'

describe API::GroupHooks, 'GroupHooks', api: true do
  include ApiHelpers

  let!(:group) { create(:group, :private) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:hook) do
    create(:group_hook,
           :all_events_enabled,
           group: group,
           url: 'http://example.com',
           enable_ssl_verification: true)
  end

  before do
    group.add_owner(user)
    group.add_developer(user2)
  end

  describe 'GET /groups/:id/hooks' do
    context 'authorized user' do
      it 'returns group hooks' do
        get api("/groups/#{group.id}/hooks", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.count).to eq(1)
        expect(json_response.first['url']).to eq("http://example.com")
        expect(json_response.first['issues_events']).to eq(true)
        expect(json_response.first['push_events']).to eq(true)
        expect(json_response.first['merge_requests_events']).to eq(true)
        expect(json_response.first['tag_push_events']).to eq(true)
        expect(json_response.first['note_events']).to eq(true)
        expect(json_response.first['build_events']).to eq(true)
        expect(json_response.first['pipeline_events']).to eq(true)
        expect(json_response.first['wiki_page_events']).to eq(true)
        expect(json_response.first['enable_ssl_verification']).to eq(true)
      end

      it 'returns 404 if group is not found' do
        get api('/groups/123/hooks', user)

        expect(response).to have_http_status(404)
      end
    end

    context 'unauthorized user' do
      it 'does not access project hooks' do
        get api("/groups/#{group.id}/hooks", user2)

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'GET /groups/:id/hooks/:hook_id' do
    context 'authorized user' do
      it 'returns a group hook' do
        get api("/groups/#{group.id}/hooks/#{hook.id}", user)

        expect(response).to have_http_status(200)
        expect(json_response['url']).to eq(hook.url)
        expect(json_response['issues_events']).to eq(hook.issues_events)
        expect(json_response['push_events']).to eq(hook.push_events)
        expect(json_response['merge_requests_events']).to eq(hook.merge_requests_events)
        expect(json_response['tag_push_events']).to eq(hook.tag_push_events)
        expect(json_response['note_events']).to eq(hook.note_events)
        expect(json_response['build_events']).to eq(hook.build_events)
        expect(json_response['pipeline_events']).to eq(hook.pipeline_events)
        expect(json_response['wiki_page_events']).to eq(hook.wiki_page_events)
        expect(json_response['enable_ssl_verification']).to eq(hook.enable_ssl_verification)
      end

      it 'returns 404 if the hook id is not available' do
        get api("/groups/#{group.id}/hooks/1234", user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Hook Not Found')
      end

      it 'returns 404 if group is not found' do
        get api("/groups/123/hooks/#{hook.id}", user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Group Not Found')
      end
    end

    context 'unauthorized user' do
      it 'does not access an existing hook' do
        get api("/groups/#{group.id}/hooks/#{hook.id}", user2)

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST /groups/:id/hooks' do
    context 'authorized user' do
      it 'adds a hook to a groups' do
        expect do
          post api("/groups/#{group.id}/hooks", user), url: "http://example.com", issues_events: true
        end.to change {group.hooks.count}.by(1)

        expect(response).to have_http_status(201)
        expect(json_response['url']).to eq('http://example.com')
        expect(json_response['issues_events']).to eq(true)
        expect(json_response['push_events']).to eq(true)
        expect(json_response['merge_requests_events']).to eq(false)
        expect(json_response['tag_push_events']).to eq(false)
        expect(json_response['note_events']).to eq(false)
        expect(json_response['build_events']).to eq(false)
        expect(json_response['pipeline_events']).to eq(false)
        expect(json_response['wiki_page_events']).to eq(false)
        expect(json_response['enable_ssl_verification']).to eq(true)
        expect(json_response).not_to include('token')
      end

      it 'adds the token without including it in the response' do
        token = 'secret token'

        expect do
          post api("/groups/#{group.id}/hooks", user), url: "http://example.com", token: token
        end.to change {group.hooks.count}.by(1)

        expect(response).to have_http_status(201)
        expect(json_response['url']).to eq('http://example.com')
        expect(json_response).not_to include('token')

        hook = group.hooks.find(json_response['id'])
        expect(hook.url).to eq('http://example.com')
        expect(hook.token).to eq(token)
      end

      it 'returns a 400 if url not given' do
        post api("/groups/#{group.id}/hooks", user)

        expect(response).to have_http_status(400)
        expect(json_response['error']).to eq('url is missing')
      end

      it 'returns a 400 if url not valid' do
        post api("/groups/#{group.id}/hooks", user), url: 'ftp://example.com'

        expect(response).to have_http_status(400)
      end

      it 'returns 404 if group is not found' do
        post api('/groups/123/hooks', user), url: 'http://example.com', issues_events: true

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Group Not Found')
      end
    end

    context 'unauthorized user' do
      it 'does not create a group hook' do
        post api("/groups/#{group.id}/hooks", user2), url: "http://example.com", token: 'secret token'

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'PUT /projects/:id/hooks/:hook_id' do
    context 'authorized user' do
      it 'updates an existing project hook' do
        put api("/groups/#{group.id}/hooks/#{hook.id}", user),
          url: 'http://example.org', push_events: false

        expect(response).to have_http_status(200)
        expect(json_response['url']).to eq('http://example.org')
        expect(json_response['issues_events']).to eq(hook.issues_events)
        expect(json_response['push_events']).to eq(false)
        expect(json_response['merge_requests_events']).to eq(hook.merge_requests_events)
        expect(json_response['tag_push_events']).to eq(hook.tag_push_events)
        expect(json_response['note_events']).to eq(hook.note_events)
        expect(json_response['build_events']).to eq(hook.build_events)
        expect(json_response['pipeline_events']).to eq(hook.pipeline_events)
        expect(json_response['wiki_page_events']).to eq(hook.wiki_page_events)
        expect(json_response['enable_ssl_verification']).to eq(hook.enable_ssl_verification)
      end

      it 'adds the token without including it in the response' do
        token = 'secret token'

        put api("/groups/#{group.id}/hooks/#{hook.id}", user), url: 'http://example.org', token: token

        expect(response).to have_http_status(200)
        expect(json_response["url"]).to eq('http://example.org')
        expect(json_response).not_to include('token')

        expect(hook.reload.url).to eq('http://example.org')
        expect(hook.reload.token).to eq(token)
      end

      it 'returns 400 error if url is not given' do
        put api("/groups/#{group.id}/hooks/#{hook.id}", user)

        expect(response).to have_http_status(400)
        expect(json_response['error']).to eq('url is missing')
      end

      it "returns a 400 error if url is not valid" do
        put api("/groups/#{group.id}/hooks/#{hook.id}", user), url: 'ftp://example.com'

        expect(response).to have_http_status(400)
      end

      it 'returns 404 if hook is not not found' do
        put api("/groups/#{group.id}/hooks/1234", user), url: 'http://example.org'

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Hook Not Found')
      end

      it 'returns 404 if group is not found' do
        put api("/groups/123/hooks/#{hook.id}", user), url: "http://foo.com"

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Group Not Found')
      end
    end

    context 'unauthorized user' do
      it 'does not update a group hook' do
        put api("/groups/#{group.id}/hooks/#{hook.id}", user2), url: "http://example.com", token: 'secret token'

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'DELETE /projects/:id/hooks/:hook_id' do
    context 'authorized user' do
      it 'deletes hook from a group' do
        expect do
          delete api("/groups/#{group.id}/hooks/#{hook.id}", user)
        end.to change {group.hooks.count}.by(-1)

        expect(response).to have_http_status(200)
      end

      it 'returns 404 if the hook id is not available' do
        delete api("/groups/#{group.id}/hooks/1234", user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Hook Not Found')
      end

      it 'returns 404 if group is not found' do
        delete api("/groups/123/hooks/#{hook.id}", user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Group Not Found')
      end
    end

    context 'unauthorized user' do
      it 'does not access an existing hook' do
        delete api("/groups/#{group.id}/hooks/#{hook.id}", user2)

        expect(response).to have_http_status(403)
      end
    end
  end
end
