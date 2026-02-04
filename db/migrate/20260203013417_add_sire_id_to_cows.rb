class AddSireIdToCows < ActiveRecord::Migration[8.0]
  def change
    add_column :cows, :sire_id, :bigint
    add_index :cows, :sire_id
    add_foreign_key :cows, :cows, column: :sire_id
  end
end
