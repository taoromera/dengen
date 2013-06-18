class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :content
      t.references :spot

      t.timestamps
    end
    add_index :comments, :spot_id
  end
end
