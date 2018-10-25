require 'spec_helper'

describe API::Users do
  set(:admin) { create(:admin) }
  set(:user) { create(:user) }

  describe 'POST /subscription' do
    let(:params) do
      { seats: 10,
        start_date: '01/01/2018',
        end_date: '01/01/2019' }
    end

    def do_post(user, authenticated_user, payload)
      post api("/users/#{user.id}/subscription", authenticated_user), payload
    end

    it 'is only accessible by the admin' do
      do_post(user, user, params)

      expect(response).to have_gitlab_http_status(403)
    end

    it 'fails when some attrs are missing' do
      params.keys.each do |name|
        do_post(user, admin, params.except(name))

        expect(response).to have_gitlab_http_status(400)
      end
    end

    it 'creates a subscription for the User' do
      do_post(user, admin, params)

      expect(response).to have_gitlab_http_status(201)
      expect(user.gitlab_subscription).to be_present
    end
  end
end
