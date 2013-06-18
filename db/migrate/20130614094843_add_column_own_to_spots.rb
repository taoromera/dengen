class AddColumnOwnToSpots < ActiveRecord::Migration
  def change
    add_column :spots, :own, :boolean
  end
end
