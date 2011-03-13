class CreateEmailHistories < ActiveRecord::Migration
  def self.up
    create_table :email_histories do |t|
      t.integer :to_email_id
      t.integer :from_email_id
      t.string :message_id
      t.string :subject
      t.datetime :open_at
      t.datetime :visit_at
      t.datetime :bounce_at
      t.string :bounce_reason

      t.timestamps
    end
  end

  def self.down
    drop_table :email_histories
  end
end
