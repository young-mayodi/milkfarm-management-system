class AddIndexesToHealthRecords < ActiveRecord::Migration[8.0]
  def change
    # Add composite indexes for better query performance
    add_index :health_records, [ :cow_id, :recorded_at ], name: 'index_health_records_on_cow_and_date'
    add_index :health_records, [ :health_status, :recorded_at ], name: 'index_health_records_on_status_and_date'
    add_index :health_records, :recorded_at, name: 'index_health_records_on_recorded_at'

    # Add indexes for common filter conditions
    add_index :health_records, [ :health_status ], name: 'index_health_records_on_status'
    add_index :health_records, [ :cow_id, :health_status ], name: 'index_health_records_on_cow_and_status'

    # Add index for temperature queries
    add_index :health_records, :temperature, name: 'index_health_records_on_temperature'
  end
end
