class CreateCows < ActiveRecord::Migration[8.0]
  def change
    create_table :cows do |t|
      t.string :name
      t.string :tag_number
      t.string :breed
      t.integer :age
      t.references :farm, null: false, foreign_key: true
      t.string :group_name
      t.string :status

      t.timestamps
    end
  end
end
