class CreateEmailArchives < ActiveRecord::Migration
  def self.up
    create_table :email_archives do |t|
      t.string :message_id
      t.binary :body_gzip

      t.timestamps
    end
    add_index :email_archives, :message_id
  end

  def self.down
    drop_table :email_archives
  end
end
