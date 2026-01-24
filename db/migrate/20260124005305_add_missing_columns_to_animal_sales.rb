class AddMissingColumnsToAnimalSales < ActiveRecord::Migration[8.0]
  def change
    add_column :animal_sales, :buyer_contact, :string
    add_column :animal_sales, :weight_at_sale, :decimal
  end
end
