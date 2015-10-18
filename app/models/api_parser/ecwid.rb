require 'ecwid_api'

module ApiParser
  class Ecwid
    def client
      @client ||= EcwidApi::Client.new(EcwidVoogSync::Application.config.app.ecwid.shop_id, EcwidVoogSync::Application.config.app.ecwid.api3_access_token)
    end

    def cache_categories!
      client.categories.all(hidden_categories: true).map do |c|
        category = Category.find_or_initialize_by(ecwid_id: c.id)
        category.attributes = {
          name: c.name,
          ecwid_enabled: c.enabled,
          ecwid_parent_id: c.parent_id,
          ecwid_synced_at: Time.now
        }
        category if category.save
      end.compact
    end

    def all_products
      client.products.all
    end

    def last_product_update
      Time.parse(client.get('latest-stats').body['productsUpdated'])
    end
  end
end
