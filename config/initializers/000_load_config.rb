require 'ostruct'

Figaro.require_keys(
  'EV_SYNC_ECWID_SHOP_ID', 'EV_SYNC_ECWID_API3_ACCESS_TOKEN',
  'EV_SYNC_VOOG_HOST', 'EV_SYNC_VOOG_API_TOKEN'
) if Rails.env.production?

EcwidVoogSync::Application.configure do
  # Application general configuration
  config.app = OpenStruct.new
  # Setup Ecwid API v3 (http://api.ecwid.com)
  config.app.ecwid = OpenStruct.new
  config.app.ecwid.shop_id = ENV['EV_SYNC_ECWID_SHOP_ID'].presence
  config.app.ecwid.api3_access_token = ENV['EV_SYNC_ECWID_API3_ACCESS_TOKEN'].presence
  config.app.ecwid.api3_api_enabled = config.app.ecwid.shop_id.present? && config.app.ecwid.api3_access_token.present?

  # Voog API (http://www.voog.com/developers/api)
  config.app.voog = OpenStruct.new(
    host: ENV['EV_SYNC_VOOG_HOST'].presence,
    api_token: ENV['EV_SYNC_VOOG_API_TOKEN'].presence,
    products_layout_name: ENV['EV_SYNC_VOOG_PRODUCTS_LAYOUT_NAME'].presence,
    products_element_definition: ENV['EV_SYNC_VOOG_PRODUCTS_ELEMENT_DEFINITION'].presence,
    products_parent_path: ENV['EV_SYNC_VOOG_PRODUCTS_PARENT_PATH'].presence
  )
  config.app.voog.enabled = config.app.voog.host.present? && config.app.voog.api_token.present?
end
