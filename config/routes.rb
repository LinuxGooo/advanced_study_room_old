Asr::Application.routes.draw do
  
  ActiveAdmin.routes(self)
  devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :users
  resources :pages, :users, :admin, :manage, :brackets
  resources :divisions do
    resources :brackets
  end
  
  match '/manage', :to => 'manage#index'
  match '/update', :to => 'manage#update'
  match '/rules', :to => 'manage#rules'
  
  match '/contact', :to => 'pages#contact'
  match '/home', :to => 'pages#home'
  match '/about', :to => 'pages#about'
  match '/league', :to => 'pages#league'
  match '/results', :to => 'pages#results'
  match '/prizes', :to => 'pages#prizes'
  match '/news', :to => 'pages#news'
  match '/users', :to => 'users#index'
  match '/users/:id', :to => 'users#show'
  
  match '/alpha', :to => 'pages#alpha'
  match '/beta_i', :to => 'pages#beta_i'
  match '/beta_ii', :to => 'pages#beta_ii'
  match '/gamma_i', :to => 'pages#gamma_i'
  match '/gamma_ii', :to => 'pages#gamma_ii'
  match '/gamma_iii', :to => 'pages#gamma_iii'
  match '/gamma_iv', :to => 'pages#gamma_iv'
  match '/delta', :to => 'pages#delta'
  
  match '/division_form', :to => 'divisions#division_form'
  
  root :to => "pages#home"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
