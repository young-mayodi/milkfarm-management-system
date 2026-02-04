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
          [:production_records, :cows].each do |assoc|
            begin
              Farm.reset_counters(farm.id, assoc) if Farm.reflect_on_association(assoc)
            rescue => e
              # Skip if association doesn't exist or counter cache column not found
            end
          end
        end

        Cow.unscoped.find_each do |cow|
          [:production_records, :health_records, :breeding_records, :vaccination_records].each do |assoc|
            begin
              Cow.reset_counters(cow.id, assoc) if Cow.reflect_on_association(assoc)
            rescue => e
              # Skip if association doesn't exist or counter cache column not found
            end
          end
        end
      end
    end
  end
end
