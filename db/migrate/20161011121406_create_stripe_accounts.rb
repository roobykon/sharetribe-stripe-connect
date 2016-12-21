class CreateStripeAccounts < ActiveRecord::Migration
  def change
    create_table :stripe_accounts do |t|
      t.string      :person_id
      t.string      :publishable_key
      t.string      :secret_key
      t.string      :stripe_user_id
      t.string      :currency
      t.string      :stripe_account_type
      t.text        :stripe_account_status
      
      t.timestamps null: false
    end
  end
end
