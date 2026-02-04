class AddCounterCachesToFarmsAndCows < ActiveRecord::Migration[8.0]
  def change
    # Add counter caches to farms table
    add_column :farms, :production_records_count, :integer, default: 0, null: false unless column_exists?(:farms, :production_records_count)
    add_column :farms, :cows_count, :integer, default: 0, null: false unless column_exists?(:farms, :cows_count)

    # Add counter caches to cows table
    add_column :cows, :production_records_count, :integer, default: 0, null: false unless column_exists?(:cows, :production_records_count)
    add_column :cows, :health_records_count, :integer, default: 0, null: false unless column_exists?(:cows, :health_records_count)
    add_column :cows, :breeding_records_count, :integer, default: 0, null: false unless column_exists?(:cows, :breeding_records_count)
    add_column :cows, :vaccination_records_count, :integer, default: 0, null: false unless column_exists?(:cows, :vaccination_records_count)

    # Reset counters after adding columns
    reversible do |dir|
      dir.up do
        Farm.find_each do |farm|
          Farm.reset_counters(farm.id, :production_records) if Farm.reflect_on_association(:production_records)
          Farm.reset_counters(farm.id, :cows) if Farm.reflect_on_association(:cows)
        end

        Cow.unscoped.find_each do |cow|
          Cow.reset_counters(cow.id, :production_records) if Cow.reflect_on_association(:production_records)
          Cow.reset_counters(cow.id, :health_records) if Cow.reflect_on_association(:health_records)
          Cow.reset_counters(cow.id, :breeding_records) if Cow.reflect_on_association(:breeding_records)
          Cow.reset_counters(cow.id, :vaccination_records) if Cow.reflect_on_association(:vaccination_records)
        end
      end
    end
  end
end
