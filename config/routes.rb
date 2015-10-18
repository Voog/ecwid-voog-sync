Rails.application.routes.draw do
  post 'ecwid_webhook' => 'ecwid_webhooks#create', as: :ecwid_webhook
  match '(*page)', via: :all, to: proc { |_env| [404, {'Content-Type' => 'text/plain'}, ['Not found.']] }
end
