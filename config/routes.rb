Rails.application.routes.draw do
  
  post 'globalstar/stu'
  post 'globalstar/prv'

  get 'geofence/check'

  post 'gl200/msg'
  post 'gl300/msg'
  get 'gl300/work'
  post 'spot_trace/msg'
  post 'gps306a/msg'
  post 'xexun_tk1022/msg'
  post 'smart_bdgps/msg'

  # =+++++ API +++++=
  get '/v1/device/gl200/decode' => 'api/v1/device/gl200#decode'
  post '/v1/device/gl200/decode' => 'api/v1/device/gl200#decode'

  get '/v1/device/spot/decode' => 'api/v1/device/spot#decode'
  post '/v1/device/spot/decode' => 'api/v1/device/spot#decode'

  get '/v1/device/smart_one_b/decode' => 'api/v1/device/smart_one_b#decode'
  post '/v1/device/smart_one_b/decode' => 'api/v1/device/smart_one_b#decode'

  get '/v1/device/gps306a/decode' => 'api/v1/device/gps306a#decode'
  post '/v1/device/gps306a/decode' => 'api/v1/device/gps306a#decode'

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
