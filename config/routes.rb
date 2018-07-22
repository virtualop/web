Rails.application.routes.draw do
  get 'map' => 'map#accounts'
  get 'map/index'
  get 'map/accounts'
  get 'map/account/:account', to: 'map#account'
  get 'map/group'
  get 'map/host'
  get 'map/host_fragment'

  get 'machines' => 'machines#index'
  get 'machines/index'
  get 'machines/scan/:machine', to: 'machines#scan', machine: /[^\/]+/
  get 'machines/show/:machine', to: 'machines#show', machine: /[^\/]+/
  get 'machines/services/:machine', to: 'machines#services', machine: /[^\/]+/
  get 'machines/traffic/:machine', to: 'machines#traffic', machine: /[^\/]+/
  # deprecated:
  get 'machines/:machine', to: 'machines#show', machine: /[^\/]+/

  post 'machines/new'
  delete 'machines/delete'

  get 'machines/service_icon/:service', to: 'machines#service_icon', service: /[^\/]+/
  get 'machines/service_params/:service', to: 'machines#service_params', service: /[^\/]+/

  post 'machines/install_service', to: 'machines#install_service'

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
  get 'dev/git_pull/:working_copy' => 'dev#git_pull'
  get 'dev/git_push/:working_copy' => 'dev#git_push'
  get 'dev/git_diff/:working_copy(/:file)' => 'dev#git_diff', file: /.+/
  get 'dev/new_diff/:working_copy(/:file)' => 'dev#new_diff', file: /.+/
  get 'dev/git_status/:working_copy' => 'dev#git_status'
  post 'dev/commit' => 'dev#commit'
  post 'dev/add_file/:working_copy/:file' => 'dev#add_file', file: /.+/

  get 'log' => 'log#index'
  get 'log/index'

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  root to: 'machines#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
