class AddSecurityLevelToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :security_level, :integer
  end
end
