class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.string :email, unique: true
      t.timestamps
    end
    add_index :contacts, :email, :unique => true
  end
end
