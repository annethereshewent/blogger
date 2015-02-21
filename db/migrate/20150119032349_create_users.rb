class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username
      t.string :password
      t.string :displayname
      t.string :blog_title
      t.string :profile_pic
      t.string :description

      t.timestamps
    end
  end
end
