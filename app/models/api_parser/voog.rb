require 'voog_api'

module ApiParser
  class Voog
    class << self; attr_accessor :layout_for_product, :element_definition_for_product, :products_parent_page end
    # Store predefined remote values in class level
    @layout_for_product = nil
    @element_definition_for_product = nil
    @products_parent_page = nil

    # Fetch all elements for requested API resource
    def paginated(api_method, opt = {})
      opt[:per_page] = 250

      data = client.send(api_method, opt)
      last_response = client.last_response

      # Where there has "next" key in response Links header then load next page.
      while last_response.rels[:next]
        last_response = last_response.rels[:next].get
        data.concat(last_response.data) if last_response.data.is_a?(Array)
      end

      data
    end

    # Voog client
    def client
      @client ||= ::Voog::Client.new(EcwidVoogSync::Application.config.app.voog.host, EcwidVoogSync::Application.config.app.voog.api_token)
    end

    # Get layout for product category (elements)
    def layout_for_products
      self.class.layout_for_product ||= client.layouts(content_type: 'elements').detect do |e|
        e.title == EcwidVoogSync::Application.config.app.voog.products_layout_name
      end
    end

    # Get element definition for product (element)
    def element_definition_for_product
      self.class.element_definition_for_product ||= client.element_definitions(
        'q.element_definition.title' => EcwidVoogSync::Application.config.app.voog.products_element_definition
      ).first
    end

    # Get product categories parent page
    def products_parent_page
      self.class.products_parent_page ||= begin
        if EcwidVoogSync::Application.config.app.voog.products_parent_path.size == 2
          # Parent is first level page (eg "en")
          client.pages('q.language.code' => EcwidVoogSync::Application.config.app.voog.products_parent_path, 'q.page.path' => '').first
        else
          # Sub-page
          client.pages('q.page.path' => EcwidVoogSync::Application.config.app.voog.products_parent_path).first
        end
      end
    end

    # Create or update category in Voog CMS.
    # Parameters:
    #   forced_update - forced update (default false)
    def push_category_to_server!(category, options = {})
      forced_update = options.fetch(:forced_update, false)

      if category.voog_page_id.blank? && category.ecwid_id.present?
        client.create_page(category_payload(category, create_action: true))
      elsif category.voog_page_id.present? && (forced_update || category.ecwid_enabled != category.voog_enabled)
        update_page(category)
      end
    end

    # Create new page (category) object
    def create_new_page(category)
      client.create_page(category_payload(category, create_action: true))
    end

    # Update existing page (category) object
    def update_page(category)
      client.update_page(category.voog_page_id, category_payload(category))
    rescue Faraday::ResourceNotFound
      create_new_element(category)
    end

    # Create or update element in Voog CMS
    def push_element_to_server!(category, product, data)
      product.voog_element_id = if product.voog_element_id.present?
        update_element(category, product.voog_element_id, data).id
      else
        create_new_element(category, data).id
      end
    end

    # Create new element object
    def create_new_element(category, data)
      client.create_element(
        element_payload(category, data).merge(
          page_id: category.voog_page_id,
          element_definition_id: element_definition_for_product.id
        )
      )
    end

    # Update existing element object
    def update_element(category, element_id, data)
      client.update_element(element_id, element_payload(category, data))
    rescue Faraday::ResourceNotFound
      create_new_element(category, data)
    end

    # Delete existing element object
    def delete_element(element_id)
      client.delete_element(element_id)
    rescue Faraday::ResourceNotFound
      # Already deleted
      nil
    end

    # Fetch categories data from Voog CMS and cache them.
    def cache_categories!
      paginated(:pages, 'q.page.content_type' => 'elements', 'q.page.layout_id' => layout_for_products.id).map do |p|
        if p.data.external_category_id.present?
          category = Category.find_or_initialize_by(ecwid_id: p.data.external_category_id)
          category.attributes = {
            voog_page_id: p.id,
            voog_enabled: !p.hidden,
            voog_synced_at: Time.now
          }
          category if category.save
        else
          Rails.logger.warn "There has page '#{p.path}' in Voog where 'data.external_category_id' is not set!"
          nil
        end
      end.compact
    end

    # Fetch products (elements) data from Voog CMS and cache them.
    def cache_products!
      paginated(:elements, include_values: true, 'q.element_definition.title' => EcwidVoogSync::Application.config.app.voog.products_element_definition).map do |e|
        if e.values.external_id.present? && e.values.external_category_id.present?
          product = Product.find_or_initialize_by(ecwid_catrgory_id: e.values.external_category_id, voog_element_id: e.id)
          product.attributes = {
            ecwid_id: e.values.external_id,
            voog_synced_at: Time.now
          }
          product if product.save
        else
          Rails.logger.warn "There has element '#{e.path}' in Voog where 'value.external_id' is not set!"
          nil
        end
      end.compact
    end

    private

    def category_payload(category, options = {})
      {
        title: category.name,
        hidden: !category.ecwid_enabled,
        data: {is_category: true, external_category_id: category.ecwid_id}
      }.tap do |h|
        h.merge!(layout_id: layout_for_products.id, parent_id: products_parent_page.id) if options.fetch(:create_action, false)
      end
    end

    def element_payload(category, data)
      {
        title: data.name,
        values: {
          external_id: data.id,
          sku: data.sku,
          price: data.price,
          description: data.description,
          options: data.options.to_json,
          combinations: data.to_hash['combinations'].to_json,
          image_url: data.image_url,
          original_image_url: data.original_image_url,
          external_category_id: category.ecwid_id
        }
      }
    end
  end
end
