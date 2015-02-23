class AddUniqueToTags < ActiveRecord::Migration
  def change
  	add_index :Tags, :tag_name, unique: true
  end
end
