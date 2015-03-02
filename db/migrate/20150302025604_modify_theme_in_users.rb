class ModifyThemeInUsers < ActiveRecord::Migration
  def change
  	remove_column :users, :theme
  end
end
