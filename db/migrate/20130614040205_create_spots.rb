class CreateSpots < ActiveRecord::Migration
  def change
    create_table :spots do |t|
      t.text :name
      t.text :address
      t.text :tel
      t.text :wireless
      t.text :category
      t.string :location
      t.text :website
      t.text :tags
      t.text :other
      t.integer :goods
      t.integer :bads
      t.text :eigyo_jikan

      t.timestamps
    end
  end
end
