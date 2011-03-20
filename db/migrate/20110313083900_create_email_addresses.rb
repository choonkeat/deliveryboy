class CreateEmailAddresses < ActiveRecord::Migration
  def self.up
    create_table :email_addresses do |t|
      t.string :email
      t.string :unique
      t.datetime :allow_from_since
      t.datetime :allow_to_since
      t.datetime :soft_bounce_at
      t.datetime :hard_bounce_at
      t.string :penalized_message_id

      t.timestamps
    end
    add_index :email_addresses, :email
    add_index :email_addresses, :unique
  end

  def self.down
    drop_table :email_addresses
  end
end
