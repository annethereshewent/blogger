class AddThemeIdToUsers < ActiveRecord::Migration
  def change
  	change_table :users do |t|
  		t.references :theme, index: true
  	end
  end
end
