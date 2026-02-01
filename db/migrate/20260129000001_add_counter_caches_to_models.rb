class AddCounterCachesToModels < ActiveRecord::Migration[8.0]
  def up
    # Add counter cache columns
    add_column :farms, :production_records_count, :integer, default: 0, null: false unless column_exists?(:farms, :production_records_count)
    add_column :farms, :sales_records_count, :integer, default: 0, null: false unless column_exists?(:farms, :sales_records_count)
    add_column :cows, :health_records_count, :integer, default: 0, null: false unless column_exists?(:cows, :health_records_count)
    add_column :cows, :breeding_records_count, :integer, default: 0, null: false unless column_exists?(:cows, :breeding_records_count)
    add_column :cows, :vaccination_records_count, :integer, default: 0, null: false unless column_exists?(:cows, :vaccination_records_count)
    add_column :cows, :production_records_count, :integer, default: 0, null: false unless column_exists?(:cows, :production_records_count)
    
    # Backfill existing counts (do this in batches for safety)
    say_with_time "Backfilling farm counter caches..." do
      Farm.find_each do |farm|
        Farm.reset_counters(farm.id, :production_records, :sales_records)
      end
    end
    
    say_with_time "Backfilling cow counter caches..." do
      Cow.find_each do |cow|
        Cow.reset_counters(cow.id, :health_records, :breeding_records, :vaccination_records, :production_records)
      end
    end
  end
  
  def down
    remove_column :farms, :production_records_count if column_exists?(:farms, :production_records_count)
    remove_column :farms, :sales_records_count if column_exists?(:farms, :sales_records_count)
    remove_column :cows, :health_records_count if column_exists?(:cows, :health_records_count)
    remove_column :cows, :breeding_records_count if column_exists?(:cows, :breeding_records_count)
    remove_column :cows, :vaccination_records_count if column_exists?(:cows, :vaccination_records_count)
    remove_column :cows, :production_records_count if column_exists?(:cows, :production_records_count)
  end
end
