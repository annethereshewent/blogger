class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.text :post
      t.integer :edited
      t.integer :num_comments
      t.references :user, index: true

      t.timestamps
    end
  end
end
