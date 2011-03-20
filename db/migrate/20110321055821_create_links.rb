class CreateLinks < ActiveRecord::Migration
  def self.up
    create_table :links do |t|
      t.string :unique
      t.string :url

      t.timestamps
    end
    add_index :links, :unique
  end

  def self.down
    drop_table :links
  end
end
