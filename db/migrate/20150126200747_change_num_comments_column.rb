class ChangeNumCommentsColumn < ActiveRecord::Migration
  def change
  	change_column :posts, :num_comments, :integer, :default => 0
  end
end
