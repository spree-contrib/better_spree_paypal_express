Spree::Core::Engine.routes.append do
  post '/paypal', :to => 'paypal#express'
  get '/paypal/confirm', :to =>  "paypal#confirm"
  get '/paypal/cancel', :to =>   "paypal#cancel"
  get '/paypal/notify', :to =>   "paypal#notify"
end
