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

require 'rails_helper'

RSpec.describe StripePaymentGateway, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
