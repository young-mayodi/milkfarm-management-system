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
        begin
          Farm.update_counters(farm.id, production_records_count: farm.production_records.count) if defined?(ProductionRecord)
          Farm.update_counters(farm.id, sales_records_count: farm.sales.count) if defined?(Sale)
        rescue => e
          puts "Skipping farm #{farm.id}: #{e.message}"
        end
      end
    end
    
    say_with_time "Backfilling cow counter caches..." do
      Cow.find_each do |cow|
        begin
          Cow.update_counters(cow.id, health_records_count: cow.health_records.count) if cow.respond_to?(:health_records)
          Cow.update_counters(cow.id, breeding_records_count: cow.breeding_records.count) if cow.respond_to?(:breeding_records)
          Cow.update_counters(cow.id, vaccination_records_count: cow.vaccination_records.count) if cow.respond_to?(:vaccination_records)
          Cow.update_counters(cow.id, production_records_count: cow.production_records.count) if cow.respond_to?(:production_records)
        rescue => e
          puts "Skipping cow #{cow.id}: #{e.message}"
        end
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
