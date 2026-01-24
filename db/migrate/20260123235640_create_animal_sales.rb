class CreateAnimalSales < ActiveRecord::Migration[8.0]
  def change
    create_table :animal_sales do |t|
      t.references :cow, null: false, foreign_key: true
      t.references :farm, null: false, foreign_key: true
      t.date :sale_date
      t.decimal :sale_price
      t.string :buyer
      t.string :animal_type
      t.text :notes

      t.timestamps
    end
  end
end
