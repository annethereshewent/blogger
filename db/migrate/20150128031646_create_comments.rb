class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :comment
      t.integer :parent
      t.references :user, index: true
      t.references :post, index: true

      t.timestamps
    end
  end
end
