Rails.application.routes.draw do
  get 'map' => 'map#index'
  get 'map/index'

  get 'map/account'

  get 'map/host/:machine', to: 'map#host', machine: /[^\/]+/
  get 'map/host_fragment/:machine', to: 'map#host_fragment', machine: /[^\/]+/
  get 'map/group/:name', to: 'map#group'
  post 'map/:machine/new_vm', to: 'map#new_vm', machine: /[^\/]+/

  get 'machines' => 'machines#index'
  get 'machines/index'
  get 'machines/:machine/delete_record', to: 'machines#delete_record', machine: /[^\/]+/

  get 'machines/map'
  get 'machines/service_icon/:service', to: 'machines#service_icon', service: /[^\/]+/
  post 'machines/:machine/new_vm', to: 'machines#new_vm', machine: /[^\/]+/
  post 'machines/:machine/delete_vm', to: 'machines#delete_vm', machine: /[^\/]+/
  get 'machines/:machine/installation_status/:vm', to: 'machines#installation_status', machine: /[^\/]+/, vm: /[^\/\?]+/
  get 'machines/:machine', to: 'machines#show', machine: /[^\/]+/


  get 'commands/index'
  get 'commands' => 'commands#index'
  get 'commands/:command' => 'commands#command', command: /[^\/]+/

  get 'plugins/index'
  get 'plugins' => 'plugins#index'
  get 'plugins/:plugin', to: 'plugins#show'
  post 'plugins' => 'plugins#create'

  get 'dev' => 'dev#index'
  get 'dev/index'
  get 'dev/reset'

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
