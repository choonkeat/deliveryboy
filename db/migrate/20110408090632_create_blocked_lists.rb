class CreateBlockedLists < ActiveRecord::Migration
  def self.up
    create_table :blocked_lists do |t|
      t.integer :email_address_id
      t.string :sender

      t.timestamps
    end
    add_index :blocked_lists, :email_address_id
  end

  def self.down
    drop_table :blocked_lists
  end
end
