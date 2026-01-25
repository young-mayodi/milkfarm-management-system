class AddAdditionalPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add composite indexes for common query patterns observed in logs
    
    # For cow status and farm filtering (used heavily in index pages)
    add_index :cows, [:status, :farm_id, :name], name: 'idx_cows_status_farm_name' unless index_exists?(:cows, [:status, :farm_id, :name])
    
    # For calf filtering and sorting
    add_index :cows, [:age, :status, :farm_id], name: 'idx_cows_age_status_farm' unless index_exists?(:cows, [:age, :status, :farm_id])
    
    # For mother-calf relationships (used in calves controller)
    add_index :cows, [:mother_id, :farm_id], name: 'idx_cows_mother_farm' unless index_exists?(:cows, [:mother_id, :farm_id])
    
    # For production record queries by date range
    add_index :production_records, [:production_date, :farm_id, :cow_id], name: 'idx_production_date_farm_cow' unless index_exists?(:production_records, [:production_date, :farm_id, :cow_id])
    
    # For recent production queries (last 7 days, 30 days)
    add_index :production_records, [:cow_id, :production_date, :total_production], name: 'idx_production_cow_date_total' unless index_exists?(:production_records, [:cow_id, :production_date, :total_production])
    
    # For farm-wide analytics
    add_index :production_records, [:farm_id, :production_date, :total_production], name: 'idx_production_farm_date_total' unless index_exists?(:production_records, [:farm_id, :production_date, :total_production])
    
    # For health, breeding, vaccination records (only if tables exist and have farm_id column)
    if table_exists?(:health_records) && column_exists?(:health_records, :farm_id)
      add_index :health_records, [:cow_id, :farm_id, :created_at], name: 'idx_health_cow_farm_created' unless index_exists?(:health_records, [:cow_id, :farm_id, :created_at])
    elsif table_exists?(:health_records)
      add_index :health_records, [:cow_id, :created_at], name: 'idx_health_cow_created' unless index_exists?(:health_records, [:cow_id, :created_at])
    end
    
    if table_exists?(:breeding_records) && column_exists?(:breeding_records, :farm_id)
      add_index :breeding_records, [:cow_id, :farm_id, :created_at], name: 'idx_breeding_cow_farm_created' unless index_exists?(:breeding_records, [:cow_id, :farm_id, :created_at])
    elsif table_exists?(:breeding_records)
      add_index :breeding_records, [:cow_id, :created_at], name: 'idx_breeding_cow_created' unless index_exists?(:breeding_records, [:cow_id, :created_at])
    end
    
    if table_exists?(:vaccination_records) && column_exists?(:vaccination_records, :farm_id)
      add_index :vaccination_records, [:cow_id, :farm_id, :created_at], name: 'idx_vaccination_cow_farm_created' unless index_exists?(:vaccination_records, [:cow_id, :farm_id, :created_at])
    elsif table_exists?(:vaccination_records)
      add_index :vaccination_records, [:cow_id, :created_at], name: 'idx_vaccination_cow_created' unless index_exists?(:vaccination_records, [:cow_id, :created_at])
    end
  end
end
