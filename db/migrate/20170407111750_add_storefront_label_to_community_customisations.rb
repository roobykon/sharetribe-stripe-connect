class AddStorefrontLabelToCommunityCustomisations < ActiveRecord::Migration
  def change
    add_column(:community_customizations, :storefront_label, :string) unless column_exists? :community_customizations, :storefront_label
  end
end
