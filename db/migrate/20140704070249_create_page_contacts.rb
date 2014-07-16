class CreatePageContacts < ActiveRecord::Migration
  def change
    create_table :page_contacts do |t|
      t.references :page, index: true
      t.references :contact, index: true
    end
    add_index :page_contacts, [:page_id, :contact_id], unique: true
  end
end
