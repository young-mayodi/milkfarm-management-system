class AddNightProductionToProductionRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :production_records, :night_production, :decimal, precision: 8, scale: 2, default: 0.0
  end
end
