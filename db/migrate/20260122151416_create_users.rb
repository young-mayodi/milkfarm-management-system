class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :role, default: 'farm_worker'
      t.references :farm, null: false, foreign_key: true
      t.boolean :active, default: true
      t.datetime :last_sign_in_at
      t.string :phone

      t.timestamps
    end
    
    add_index :users, :email, unique: true
    add_index :users, [:farm_id, :role]
  end
end
