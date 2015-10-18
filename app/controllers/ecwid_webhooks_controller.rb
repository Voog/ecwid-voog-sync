class EcwidWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    if valid_request?
      case params['eventType']
      when 'product.updated', 'product.created'
        if params['entityId'].present?
          product_data = ApiParser::Ecwid.new.client.products.find(params['entityId'])
          Synchronizer.new.sync_product(product_data, forced_update: true) if product_data.present?
        end
      when 'product.deleted'
        Products.where(ecwid_id: params['entityId']).each(&:destroy) if params['entityId'].present?
      end
    end

    render json: {}, status: :ok
  end

  private

  def valid_request?
    request.headers['X-ECWID-WEBHOOK-SIGNATURE'].present? && params['storeId'] == EcwidVoogSync::Application.config.app.ecwid.shop_id
  end
end
