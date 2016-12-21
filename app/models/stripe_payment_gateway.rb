# == Schema Information
#
# Table name: stripe_payment_gateways
#
#  id                     :integer          not null, primary key
#  community_id           :integer
#  stripe_publishable_key :string(255)
#  stripe_secret_key      :string(255)
#  stripe_client_id       :string(255)
#  commission_from_seller :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class StripePaymentGateway < ActiveRecord::Base

  def name
    "stripe"
  end

  def configured?
    [
      stripe_publishable_key,
      stripe_secret_key,
      stripe_client_id
    ].all? { |x| x.present? }
  end

  def tranfers_enabled?
    configured?
  end

  def gateway_type
    :stripe
  end
  
end
