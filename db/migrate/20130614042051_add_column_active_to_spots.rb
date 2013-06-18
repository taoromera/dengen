class AddColumnActiveToSpots < ActiveRecord::Migration
  def change
    add_column :spots, :active, :boolean
  end
end
