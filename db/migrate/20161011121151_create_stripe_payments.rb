class CreateStripePayments < ActiveRecord::Migration
  def change
    create_table :stripe_payments do |t|
      t.string   "payer_id"
      t.string   "recipient_id"
      t.string   "organization_id"
      t.integer  "transaction_id"
      t.string   "status"
      t.integer  "community_id"
      t.integer  "sum_cents"
      t.string   "currency"
      t.string   "stripe_transaction_id"

      t.timestamps null: false
    end
  end
end
