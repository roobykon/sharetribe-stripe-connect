class AddCommissionFromSellerToCommunity < ActiveRecord::Migration
  def change
    add_column :communities, :commission_from_seller, :integer
  end
end
