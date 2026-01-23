class CreateFarms < ActiveRecord::Migration[8.0]
  def change
    create_table :farms do |t|
      t.string :name
      t.string :location
      t.string :contact_phone
      t.string :owner

      t.timestamps
    end
  end
end
