# frozen_string_literal: true

require 'rails_helper'

# Request specs render the real templates. The controller specs below them run
# with view rendering off, which is exactly how a 500 in a re-rendered form can
# hide behind a green suite.
RSpec.describe 'Users', type: :request do
  let(:valid_attributes) do
    { email: 'ada@example.com', password: 'Analytical1!', password_confirmation: 'Analytical1!' }
  end

  describe 'GET /' do
    it 'renders the signup form' do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Create an account')
    end

    it 'embeds the password policy for the browser to enforce' do
      get root_path

      policy = JSON.parse(CGI.unescapeHTML(response.body[/data-user-policy-value="([^"]+)"/, 1]))
      expect(policy['minLength']).to eq(PasswordPolicy::MIN_LENGTH)
      expect(policy['rules'].map { |rule| rule['key'] })
        .to eq(PasswordPolicy::RULES.map { |rule| rule.key.to_s })
    end
  end

  describe 'POST /users' do
    it 'creates the user and redirects to the confirmation page' do
      expect { post users_path, params: { user: valid_attributes } }
        .to change(User, :count).by(1)

      expect(response).to redirect_to(user_path(User.last))
      follow_redirect!
      expect(response.body).to include('ada@example.com')
    end

    it 're-renders the form with 422 so Turbo replaces the page' do
      post users_path, params: { user: valid_attributes.merge(password: 'weak') }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('must include at least one uppercase letter')
    end

    it 're-renders the form instead of raising when the user key is missing' do
      post users_path, params: {}

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include('Required parameters are missing: user')
      expect(response.body).to include('Create an account')
    end

    it 'turns a lost uniqueness race into a form error rather than a 500' do
      allow_any_instance_of(User).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

      post users_path, params: { user: valid_attributes }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('has already been taken')
    end
  end

  describe 'GET /users/:id' do
    it 'shows the created account' do
      user = create(:user)

      get user_path(user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.email)
    end

    it 'renders a 404 page for an unknown id' do
      get user_path(id: 0)

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('Page not found')
    end
  end
end
