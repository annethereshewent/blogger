Rails.application.routes.draw do

  devise_for :users, controllers: {
    confirmations: 'users/confirmations'
  }

  get '/users/checkLogin'
  get '/users' => 'users#login'
  post '/users/validate'
  post '/users/checkLogin' => "users#checkLogin"
  get '/users/logout'
  post '/posts/:post_id/delete/' => "posts#delete", as: "delete_post"
  get '/posts/:post_id/fetch' => "posts#fetch", as: "fetch_post"
  patch '/users/:id/update' => "users#update", as: "update_user"
  get '/users/account' => 'users#account', as: 'user_account'
  root 'users#login'
  post '/users/verify'  => 'users#verify'
  post '/comments/:comment_id/reply' => 'comments#reply', as: 'comments_reply'
  get '/users/:id/tags/:tag' => 'posts#tags', as: 'user_tags'
  get '/users/:user_id/posts/:page' => 'posts#index', as: 'user_posts_page'
  post '/users/:user_id/friend' => 'users#add_friend', as: 'add_friend'
  get '/users/dashboard' => 'users#dashboard', as: 'user_dashboard'
  get '/users/checkRequests' => 'users#check_requests'
  get '/users/getRequests/:num' => 'users#get_requests'
  post '/users/:id/confirmFriend/:user_id' => 'users#confirm_friend'
  post '/posts/upload_images' => 'posts#upload_images', as: 'image_upload'
  get '/posts/:page/fetch_posts'  => 'users#fetch_posts',  as: 'fetch_posts'
  post '/users/:user_id/switch_theme' => 'users#switch_theme', as: 'switch_theme'
  get '/users/tags/:tag' => 'users#tags', as: 'dashboard_tags'
  get '/users/:user_id/isFriends' => 'users#isFriends'
  get '/users/get_user_id' => 'users#get_user_id'
  post '/posts/upload_image' => 'posts#upload_image', as: 'upload_image'
  get '/users/search/:search' => 'users#search', as: 'search'
  get '/users/:user_id/archive' => 'users#archive', as: 'user_archive'
  get '/users/:user_id/fetchArchivePosts' => 'users#fetch_archive_posts', as: 'archive_posts'
  post '/api/login' => 'api#login'
  post '/api/create_post' => 'api#create_post'
  get '/api/fetch_posts' => 'api#fetch_posts'
  get '/api/fetch_posts/:page' => 'api#fetch_posts'
  post '/api/register' => 'api#register'
  get '/users/fetch_sidebar_posts' => 'users#fetch_sidebar_posts'
  post '/users/save_sidebar_settings' => 'users#save_sidebar_settings'
  get '/users/:user_id/posts/:page/fetch_sidebar_posts' => 'posts#fetch_sidebar_posts'
  get '/api/fetch_friends' => 'api#fetch_friends'
  get '/api/fetch_comments/:post_id' => 'api#fetch_comments'
  post '/api/post_comment' => 'api#post_comment'
  post '/api/find_user' => 'api#find_user'
  post '/api/find_email' => 'api#find_email'
  post "/api/delete_post/:post_id" => 'api#delete_post'
  post '/api/edit_post/:post_id' => 'api#edit_post' 
  post '/api/upload_image/' => 'api#upload_image'
  get '/api/tag_search/:tag_name' => 'api#tag_search'
  post '/api/verify' => 'api#verify'
  post '/api/update_user' => 'api#update_user'

  resources :users do
    resources :posts do
      resources :comments
    end
  end


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
