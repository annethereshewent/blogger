class AddSidebarSettingsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :text_color, :string
    add_column :users, :background_color, :string
  end
end
