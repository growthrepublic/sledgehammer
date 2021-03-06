class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.references :website, index: true
      t.string :url
      t.integer :depth
      t.boolean :completed

      t.timestamps
    end
  end
end
