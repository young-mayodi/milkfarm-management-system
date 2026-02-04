class AddDeletedAtToCows < ActiveRecord::Migration[8.0]
  def change
    add_column :cows, :deleted_at, :datetime
    add_index :cows, :deleted_at
  end
end
