# This class synchronizes data form Ecwid store to Voog CMS.
class Synchronizer
  RATE_LIMIT = 100
  RATE_TIMEOUT = 15

  # Synchronize data between Ecwid Store and Voog CMS.
  #   Synchronizer.new.sync!
  def initialize
    @ecwid_api = ApiParser::Ecwid.new
    @voog_api = ApiParser::Voog.new
    @request_counter = 0
    @ecwid_category_products = HashWithIndifferentAccess.new { |h, k| h[k] = [] }
  end

  # Sync data between Ecwid and Voog
  # Parameters:
  #   forced_update - forced update (default false)
  def sync!(options = {})
    forced_update = options.fetch(:forced_update, false)

    # Sync categories when last sync was more than day ago
    sync_categories!(options)

    # Sync products when products last update time in Ecwid is newer than in cache.
    if forced_update || last_product_sync.blank? || last_product_sync < @ecwid_api.last_product_update + 5.minute
      fetch_products_from_voog!
      synchronize_all_products!(options)
    end

    sync_products_order! if forced_update
  end

  # Refresh cached categories data from Ecwid and Voog when last sync was more than day ago.
  # Parameters:
  #   forced_update - forced update (default false)
  def sync_categories!(options = {})
    if options.fetch(:forced_update, false) || options.fetch(:sync_order, false) || last_categories_sync.blank? || last_categories_sync < Time.now - 1.day
      categories_in_ecwid = @ecwid_api.cache_categories!.map(&:id)
      Category.where.not(id: categories_in_ecwid).update_all(ecwid_enabled: false) unless options[:sync_order]

      categories_in_voog = @voog_api.cache_categories!.map(&:id)
      Category.where.not(id: categories_in_voog).update_all(voog_page_id: nil) unless options[:sync_order]

      # Hide all hidden and removed categories in Voog.
      Category.where(ecwid_enabled: false, voog_enabled: true).where.not(voog_page_id: ['', nil]).each do |category|
        update_category(category, forced_update: true)
        increment_request_counter!
      end unless options[:sync_order]

      # Ensure that categories are in same order in Ecwid and Voog.
      sync_categories_order!(categories_in_ecwid, categories_in_voog)
    end
  end

  # Refresh cached categories data from Ecwid and Voog
  # Parameters:
  #   forced_update - forced update (default false)
  def synchronize_all_products!(options = {})
    existing_product_ids = []

    @ecwid_api.all_products.each do |p|
      if p.enabled
        existing_product_ids << p.id
        sync_product(p, options)
      end
    end

    # Delete all products that are not in Ecwid Store
    if existing_product_ids.present?
      Product.where.not(voog_element_id: ['', nil], ecwid_id: existing_product_ids).each do |p|
        @voog_api.delete_element(p.voog_element_id)
        p.delete
        increment_request_counter!
      end
    end
  end

  # Refresh cached products information from Voog
  # All product related elements are fetched.
  def fetch_products_from_voog!
    synced_products = @voog_api.cache_products!
    Product.where.not(id: synced_products.map(&:id)).each do |product|
      product.destroy
      increment_request_counter!
    end
  end

  # Update data when product data is changed in Ecwid.
  # Disable products and products without category are not synced.
  # All products that are not included in sync are deleted.
  def sync_product(product_data, options = {})
    forced_update = options.fetch(:forced_update, false)

    if product_data.enabled && product_data.category_ids.present?
      product_details = nil

      product_data.category_ids.each do |category_id|
        category = all_categories.detect { |e| e.ecwid_id == category_id.to_s }

        if category && category.ecwid_enabled
          # Ensure that category is exists in Voog CMS.
          update_category(category)
          product = category.products.find_or_create_by(ecwid_id: product_data.id)
          # Cache products order in Ecwid by category
          @ecwid_category_products[category_id] << product.id

          if forced_update || product.ecwid_synced_at.blank? || product.voog_synced_at.blank? || product.ecwid_synced_at < product_data.updated
            @request_counter += 1
            product.attributes = {
              name: product_data.name,
              ecwid_category_id: category_id,
              enabled: product_data.enabled,
              ecwid_synced_at: Time.now
            }
            product.save

            # Get product details once per catalog
            product_details ||= @ecwid_api.client.products.find(product_data.id)
            @voog_api.push_element_to_server!(category, product, product_details)
            product.touch(:voog_synced_at)

            increment_request_counter!
          else
            Rails.logger.info "SKIPPING: #{product_data.id} is up to date!"
          end
        else
          Rails.logger.warn "Category ##{category_id} #{category && !category.ecwid_enabled ? 'is disabled' : 'not found in database'}!"
        end
      end

      # Remove product from removed categories
      Product.where(ecwid_id: product_data.id).where.not(ecwid_category_id: product_data.category_ids, voog_element_id: ['', nil]).each do |product|
        @voog_api.delete_element(product.voog_element_id)
        product.delete
        increment_request_counter!
      end
    else
      Rails.logger.warn "Can't import product #{product_data.id}: #{product_data.enabled ? 'product is disabled' : 'no category'}."
    end
  end

  # Get data about last products sync.
  def last_categories_sync
    @last_categories_sync ||= Category.minimum(:ecwid_synced_at)
  end

  # Get data about last products sync.
  # It triggers full update when there has some product that is not fetched from Ecwid.
  def last_product_sync
    @last_product_sync ||= begin
      if Product.where(ecwid_synced_at: nil).exists?
        ''
      else
        Product.minimum(:ecwid_synced_at)
      end
    end
  end

  private

  def increment_request_counter!
    @request_counter += 1
    sleep(RATE_TIMEOUT) if @request_counter % RATE_LIMIT == 0
  end

  def update_category(category, options = {})
    result = @voog_api.push_category_to_server!(category, options)
    # Process when category has added or updated.
    if result
      category.voog_page_id = result.id
      category.voog_node_id = result.node.id
      category.voog_enabled = !result.hidden
      category.voog_synced_at = Time.now
      category.save

      # Re-sync categories and their order after update - ignore in case of forced_update since it is already synced.
      sync_categories!(sync_order: true) unless options[:forced_update]
      all_categories.reload
    end
  end

  def all_categories
    @all_categories ||= Category.all
  end

  # Ensure that categories order in Ecwid and Voog are same.
  # Input waits arrays of category ids as arguments.
  def sync_categories_order!(categories_in_ecwid, categories_in_voog)
    common_categories = categories_in_ecwid & categories_in_voog
    if common_categories.zip(categories_in_voog & categories_in_ecwid).any? { |e, v| e != v }
      common_categories.each.with_index(1) do |id, index|
        @voog_api.move_page(Category.find_by_id(id), index)
      end
    end
  end

  # Ensure that products order in Ecwid and Voog are same.
  def sync_products_order!
    @ecwid_category_products.each do |ecwid_category_id, products_in_ecwid|
      products = Product.where(ecwid_category_id: ecwid_category_id, id: products_in_ecwid).includes(:category)
      products_in_voog = products.sort { |a, b| a.voog_position.to_i <=> b.voog_position.to_i}.map(&:id)
      common_products = products_in_ecwid & products_in_voog

      if common_products.size > 1 && common_products.zip(products_in_voog & products_in_ecwid).any? { |e, v| e != v }
        common_products.each_with_index do |id, index|
          product = products.detect { |p| p.id == id }
          if index == 0
            target_id = products.detect { |p| p.id == common_products[index + 1] }.try(:voog_element_id)
            @voog_api.move_element(product, before: target_id)
          else
            target_id = products.detect { |p| p.id == common_products[index - 1] }.try(:voog_element_id)
            @voog_api.move_element(product, after: target_id)
          end
          increment_request_counter!
        end
      end
    end
  end
end
