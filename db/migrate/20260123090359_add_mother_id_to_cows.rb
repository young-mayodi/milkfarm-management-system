class AddMotherIdToCows < ActiveRecord::Migration[8.0]
  def change
    add_reference :cows, :mother, null: true, foreign_key: { to_table: :cows }
  end
end
