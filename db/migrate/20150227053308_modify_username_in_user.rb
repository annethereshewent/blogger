class ModifyUsernameInUser < ActiveRecord::Migration
  def change
  	rename_column :users, :username, :email
  end
end
