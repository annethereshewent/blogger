class AddBannerColumnToUsers < ActiveRecord::Migration[5.1]
  def up
    change_table :users do |t|
      t.attachment :banner
    end
  end

  def down
    remove_attachment :users, :banner
  end
end
