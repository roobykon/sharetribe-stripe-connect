module PaymentHelper

  def get_transaction_process(community_id:, transaction_process_id:)
    opts = {
        process_id: transaction_process_id,
        community_id: community_id
    }

    TransactionService::API::Api.processes.get(opts)
        .maybe[:process]
        .or_else(nil)
        .tap { |process|
      raise ArgumentError.new("Cannot find transaction process: #{opts}") if process.nil?
    }
  end

  def delivery_config(require_shipping_address, pickup_enabled, shipping_price, shipping_price_additional, currency)
    shipping = delivery_price_hash(:shipping, shipping_price, shipping_price_additional)
    pickup = delivery_price_hash(:pickup, Money.new(0, currency), Money.new(0, currency))

    case [require_shipping_address, pickup_enabled]
      when matches([true, true])
        [shipping, pickup]
      when matches([true, false])
        [shipping]
      when matches([false, true])
        [pickup]
      else
        []
    end
  end

  def delivery_price_hash(delivery_type, price, shipping_price_additional)
    { name: delivery_type,
      price: price,
      shipping_price_additional: shipping_price_additional,
      price_info: ListingViewUtils.shipping_info(delivery_type, price, shipping_price_additional),
      default: true
    }
  end

  # Create image sizes that might be missing
  # from a reopened listing
  def reprocess_missing_image_styles(listing)
    listing.listing_images.pluck(:id).each { |image_id|
      Delayed::Job.enqueue(CreateSquareImagesJob.new(image_id))
    }
  end

end