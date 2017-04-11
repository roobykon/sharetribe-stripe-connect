class AddProviderFieldToListings < ActiveRecord::Migration
  def change
    add_reference :listings, :person, index: true, type: :string
    add_column :listings, :status, :integer, default: 0
  end
end
