class CreateProductionRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :production_records do |t|
      t.references :cow, null: false, foreign_key: true
      t.references :farm, null: false, foreign_key: true
      t.date :production_date
      t.decimal :morning_production
      t.decimal :noon_production
      t.decimal :evening_production
      t.decimal :total_production

      t.timestamps
    end
  end
end
