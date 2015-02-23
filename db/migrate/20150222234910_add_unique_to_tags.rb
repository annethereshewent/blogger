class AddUniqueToTags < ActiveRecord::Migration
  def change
  	add_index :tags, :tag_name, unique: true
  end
end
