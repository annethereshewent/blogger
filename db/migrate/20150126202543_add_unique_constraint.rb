class AddUniqueConstraint < ActiveRecord::Migration
  def change
  	add_index(:users, :displayname, :unique => true)
  end
end
