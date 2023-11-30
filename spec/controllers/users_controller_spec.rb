# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe 'GET #new' do
    it 'assigns a new User to @user' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end

    it 'renders the :new template' do
      get :new
      expect(response).to render_template :new
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'saves the new user in the database' do
        expect do
          post :create, params: { user: attributes_for(:user) }
        end.to change(User, :count).by(1)
      end

      it 'redirects to users#show' do
        post :create, params: { user: attributes_for(:user) }
        expect(response).to redirect_to(user_path(assigns(:user)))
      end
    end

    context 'with invalid attributes' do
      it 'does not save the new user in the database' do
        expect do
          post :create, params: { user: attributes_for(:user, email: nil) }
        end.not_to change(User, :count)
      end

      it 're-renders the :new template' do
        post :create, params: { user: attributes_for(:user, email: nil) }
        expect(response).to render_template :new
      end

      it 'returns alert for missing params' do
        post :create, params: {}
        expect(flash['alert']).to eq 'Required parameters are missing: user'
      end
    end
  end

  describe 'GET #show' do
    let(:user) { create(:user) }

    context 'with valid id' do
      it 'assigns the requested user to @user' do
        get :show, params: { id: user }
        expect(assigns(:user)).to eq user
      end

      it 'renders the :show template' do
        get :show, params: { id: user }
        expect(response).to render_template :show
      end
    end

    context 'with invalid id' do
      it 'renders the not_found template' do
        get :show, params: { id: 1000 }
        expect(response).to render_template 'shared/not_found'
      end
    end
  end
end
