class CreateGoodbads < ActiveRecord::Migration
  def change
    create_table :goodbads do |t|
      t.text :token
      t.references :spot

      t.timestamps
    end
    add_index :goodbads, :spot_id
  end
end
