class RenameColumnInFriendships < ActiveRecord::Migration
  def change
  	rename_column :friendships, :users_id, :user_id
  end
end
