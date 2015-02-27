class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.references :users, index: true
      t.integer :friend_id, references: :users, index: true
      t.timestamps
    end
  end
end
