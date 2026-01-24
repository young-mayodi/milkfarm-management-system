class CreateHealthRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :health_records do |t|
      t.references :cow, null: false, foreign_key: true
      t.string :health_status
      t.decimal :temperature
      t.decimal :weight
      t.text :notes
      t.string :recorded_by
      t.datetime :recorded_at
      t.string :veterinarian

      t.timestamps
    end
  end
end
