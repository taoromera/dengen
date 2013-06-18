class AddColumnGoodToGoodbad < ActiveRecord::Migration
  def change
    add_column :goodbads, :good, :boolean
  end
end
