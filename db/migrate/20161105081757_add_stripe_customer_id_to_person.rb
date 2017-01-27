class AddStripeCustomerIdToPerson < ActiveRecord::Migration
  def change
    add_column :people, :stripe_customer_id, :string
  end
end
