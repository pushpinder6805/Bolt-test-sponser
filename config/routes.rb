# frozen_string_literal: true

Discourse::Application.routes.append do
  namespace :sponsored do
    post "/checkout" => "payments#checkout"
    post "/webhooks/:provider" => "webhooks#receive"
    post "/events" => "events#track"
    get "/stats/:id" => "stats#show"
  end

  namespace :admin, constraints: StaffConstraint.new do
    resources :sponsored_posts, only: [:index, :show, :update, :destroy] do
      member do
        put :approve
        put :reject
      end
    end
  end
end