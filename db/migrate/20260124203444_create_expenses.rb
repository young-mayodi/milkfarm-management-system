class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.references :farm, null: false, foreign_key: true
      t.string :expense_type
      t.decimal :amount
      t.text :description
      t.date :expense_date
      t.string :category

      t.timestamps
    end
  end
end
