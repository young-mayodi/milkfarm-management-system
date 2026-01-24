class CreateBreedingRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :breeding_records do |t|
      t.references :cow, null: false, foreign_key: true
      t.date :breeding_date
      t.string :bull_name
      t.string :breeding_method
      t.date :expected_due_date
      t.date :actual_due_date
      t.string :breeding_status
      t.text :notes
      t.string :veterinarian

      t.timestamps
    end
  end
end
