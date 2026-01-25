class AddIndexesToVaccinationAndBreedingRecords < ActiveRecord::Migration[8.0]
  def change
    # Vaccination Records Indexes
    add_index :vaccination_records, [ :cow_id, :vaccination_date ], name: 'index_vaccination_records_on_cow_and_date'
    add_index :vaccination_records, [ :vaccine_name, :vaccination_date ], name: 'index_vaccination_records_on_vaccine_and_date'
    add_index :vaccination_records, :vaccination_date, name: 'index_vaccination_records_on_date'
    add_index :vaccination_records, :next_due_date, name: 'index_vaccination_records_on_next_due_date'
    add_index :vaccination_records, [ :cow_id, :next_due_date ], name: 'index_vaccination_records_on_cow_and_due_date'

    # Breeding Records Indexes
    add_index :breeding_records, [ :cow_id, :breeding_date ], name: 'index_breeding_records_on_cow_and_date'
    add_index :breeding_records, [ :breeding_status, :breeding_date ], name: 'index_breeding_records_on_status_and_date'
    add_index :breeding_records, :breeding_date, name: 'index_breeding_records_on_breeding_date'
    add_index :breeding_records, :expected_due_date, name: 'index_breeding_records_on_expected_due_date'
    add_index :breeding_records, [ :breeding_status ], name: 'index_breeding_records_on_status'
    add_index :breeding_records, [ :cow_id, :breeding_status ], name: 'index_breeding_records_on_cow_and_status'
  end
end
