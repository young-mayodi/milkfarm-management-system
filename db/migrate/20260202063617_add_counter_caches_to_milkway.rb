class AddCounterCachesToMilkway < ActiveRecord::Migration[8.0]
  def change
    # Add counter cache columns
    add_column :farms, :cows_count, :integer, default: 0, null: false unless column_exists?(:farms, :cows_count)
    add_column :cows, :production_records_count, :integer, default: 0, null: false unless column_exists?(:cows, :production_records_count)
    add_column :cows, :health_records_count, :integer, default: 0, null: false unless column_exists?(:cows, :health_records_count)

    # Add composite indexes for fast queries
    add_index :production_records, [ :production_date, :farm_id ], name: 'idx_prod_date_farm' unless index_exists?(:production_records, [ :production_date, :farm_id ], name: 'idx_prod_date_farm')
    add_index :production_records, [ :production_date, :cow_id ], name: 'idx_prod_date_cow' unless index_exists?(:production_records, [ :production_date, :cow_id ], name: 'idx_prod_date_cow')
    add_index :production_records, [ :cow_id, :production_date ], name: 'idx_cow_date' unless index_exists?(:production_records, [ :cow_id, :production_date ], name: 'idx_cow_date')
    add_index :production_records, :total_production, name: 'idx_total_prod' unless index_exists?(:production_records, :total_production, name: 'idx_total_prod')

    add_index :health_records, [ :cow_id, :recorded_at ], name: 'idx_health_cow_date' unless index_exists?(:health_records, [ :cow_id, :recorded_at ], name: 'idx_health_cow_date')
    add_index :health_records, [ :health_status, :recorded_at ], name: 'idx_health_status_date' unless index_exists?(:health_records, [ :health_status, :recorded_at ], name: 'idx_health_status_date')

    add_index :cows, [ :farm_id, :status ], name: 'idx_cow_farm_status' unless index_exists?(:cows, [ :farm_id, :status ], name: 'idx_cow_farm_status')
    add_index :cows, [ :status, :breed ], name: 'idx_cow_status_breed' unless index_exists?(:cows, [ :status, :breed ], name: 'idx_cow_status_breed')
    add_index :cows, :birth_date, name: 'idx_cow_dob' unless index_exists?(:cows, :birth_date, name: 'idx_cow_dob')

    # Counter caches will be reset manually after migration
  end
end
