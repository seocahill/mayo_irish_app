class AddPlaceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :place, :string
    add_column :users, :dialect_region, :string
    add_column :users, :door, :string
    add_column :users, :onboarded_at, :datetime
  end
end
