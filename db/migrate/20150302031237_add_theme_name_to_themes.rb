class AddThemeNameToThemes < ActiveRecord::Migration
  def change
    add_column :themes, :theme_name, :string
  end
end
