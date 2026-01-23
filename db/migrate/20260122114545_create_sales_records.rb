class CreateSalesRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :sales_records do |t|
      t.references :farm, null: false, foreign_key: true
      t.date :sale_date
      t.decimal :milk_sold
      t.decimal :cash_sales
      t.decimal :mpesa_sales
      t.decimal :total_sales
      t.string :buyer

      t.timestamps
    end
  end
end
