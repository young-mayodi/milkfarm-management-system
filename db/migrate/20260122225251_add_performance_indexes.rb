class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Critical indexes for production_records table
    add_index :production_records, :production_date unless index_exists?(:production_records, :production_date)
    add_index :production_records, [:production_date, :cow_id] unless index_exists?(:production_records, [:production_date, :cow_id])
    add_index :production_records, [:production_date, :farm_id] unless index_exists?(:production_records, [:production_date, :farm_id])
    add_index :production_records, [:cow_id, :production_date] unless index_exists?(:production_records, [:cow_id, :production_date])
    add_index :production_records, [:farm_id, :production_date] unless index_exists?(:production_records, [:farm_id, :production_date])
    add_index :production_records, :total_production unless index_exists?(:production_records, :total_production)
    
    # Composite index for analytics queries (top performers)
    add_index :production_records, [:production_date, :total_production], 
              name: 'idx_production_records_date_total_desc', 
              order: { total_production: :desc } unless index_exists?(:production_records, [:production_date, :total_production])
    
    # Indexes for cows table
    add_index :cows, [:farm_id, :status] unless index_exists?(:cows, [:farm_id, :status])
    add_index :cows, :tag_number, unique: true unless index_exists?(:cows, :tag_number)
    
    # Index for sales_records if needed
    add_index :sales_records, :sale_date unless index_exists?(:sales_records, :sale_date)
    add_index :sales_records, [:farm_id, :sale_date] unless index_exists?(:sales_records, [:farm_id, :sale_date])
  end
end
