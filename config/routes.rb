Rails.application.routes.draw do
  get 'map/index'
  get 'map/group'
  get 'map/host'
  get 'map/host_fragment'

  get 'machines' => 'machines#index'
  get 'machines/index'
  get 'machines/:machine', to: 'machines#show', machine: /[^\/]+/

  post 'machines/new'
  delete 'machines/delete'

  get 'machines/service_icon/:service', to: 'machines#service_icon', service: /[^\/]+/

  # get 'machines' => 'machines#index'
  # get 'machines/index'
  # get 'machines/:machine/delete_record', to: 'machines#delete_record', machine: /[^\/]+/

  # get 'machines/map'
  # post 'machines/:machine/new_vm', to: 'machines#new_vm', machine: /[^\/]+/
  # post 'machines/:machine/delete_vm', to: 'machines#delete_vm', machine: /[^\/]+/
  # get 'machines/:machine/installation_status/:vm', to: 'machines#installation_status', machine: /[^\/]+/, vm: /[^\/\?]+/
  # get 'machines/:machine', to: 'machines#show', machine: /[^\/]+/

  get 'map' => 'map#index'
  get 'map/index'

  get 'map/account'

  get 'map/host/:machine', to: 'map#host', machine: /[^\/]+/
  get 'map/host_fragment/:machine', to: 'map#host_fragment', machine: /[^\/]+/
  get 'map/group/:name', to: 'map#group'
  post 'map/:machine/new_vm', to: 'map#new_vm', machine: /[^\/]+/

  get 'plugins/index'
  get 'plugins' => 'plugins#index'
  get 'plugins/:plugin', to: 'plugins#show'
  post 'plugins' => 'plugins#create'

  get 'commands/index'
  get 'commands' => 'commands#index'
  get 'commands/entity/:entity' => 'commands#entity', entity: /[^\/]+/
  get 'commands/:command' => 'commands#command', command: /[^\/]+/

  get 'dev' => 'dev#index'
  get 'dev/index'
  get 'dev/reset'

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
