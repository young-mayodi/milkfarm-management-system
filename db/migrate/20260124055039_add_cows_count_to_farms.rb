class AddCowsCountToFarms < ActiveRecord::Migration[8.0]
  def change
    add_column :farms, :cows_count, :integer, default: 0, null: false

    # Populate the counter cache with existing data
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE farms#{' '}
          SET cows_count = (
            SELECT COUNT(*)#{' '}
            FROM cows#{' '}
            WHERE cows.farm_id = farms.id
          )
        SQL
      end
    end
  end
end
