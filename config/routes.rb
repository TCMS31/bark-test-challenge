# frozen_string_literal: true

Rails.application.routes.draw do
  # Liveness probe for the container healthcheck: 200 once the app has booted.
  get 'up' => 'rails/health#show', as: :rails_health_check

  resources :users, only: %i[new create show]
  root 'users#new'
end
