class CreateVaccinationRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :vaccination_records do |t|
      t.references :cow, null: false, foreign_key: true
      t.string :vaccine_name
      t.date :vaccination_date
      t.date :next_due_date
      t.string :administered_by
      t.string :batch_number
      t.text :notes
      t.string :veterinarian

      t.timestamps
    end
  end
end
