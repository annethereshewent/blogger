class AddColumnToPosts < ActiveRecord::Migration
  def change
  	add_column :posts, :tags, :string
  end
end
