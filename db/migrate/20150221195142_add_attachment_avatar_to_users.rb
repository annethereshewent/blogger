class AddAttachmentAvatarToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.attachment :avatar
    end
    remove_column :users, :profile_pic
  end

  def self.down
    remove_attachment :users, :avatar
    add_column :users, :profile_pic
  end
end
