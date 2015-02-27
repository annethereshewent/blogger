class AddSenderToFriendships < ActiveRecord::Migration
  def change
    add_column :friendships, :sender, :integer
  end
end
