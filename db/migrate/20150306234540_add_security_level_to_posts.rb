class AddSecurityLevelToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :security_level, :integer
  end
end
