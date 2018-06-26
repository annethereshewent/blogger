class CreateLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :logs do |t|
      t.references :user, index: true
      t.integer :friend_id, references: :users, index: true
      t.string :message
      t.timestamp :sent_on

      t.timestamps
    end
  end
end
