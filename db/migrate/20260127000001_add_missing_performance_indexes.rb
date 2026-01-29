class AddMissingPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add composite index for breeding records date queries
    add_index :breeding_records, [:cow_id, :breeding_date], 
              name: 'index_breeding_records_on_cow_and_date',
              if_not_exists: true
    
    add_index :breeding_records, [:breeding_status, :expected_due_date], 
              name: 'index_breeding_records_on_status_and_due_date',
              if_not_exists: true
    
    # Add composite index for vaccination records date queries
    add_index :vaccination_records, [:cow_id, :vaccination_date], 
              name: 'index_vaccination_records_on_cow_and_date',
              if_not_exists: true
    
    add_index :vaccination_records, :next_due_date, 
              name: 'index_vaccination_records_on_next_due_date',
              if_not_exists: true
    
    # Add index for common date range queries on expenses
    add_index :expenses, [:farm_id, :expense_date], 
              name: 'index_expenses_on_farm_and_date',
              if_not_exists: true
    
    # Add index for animal sales date queries
    add_index :animal_sales, [:farm_id, :sale_date], 
              name: 'index_animal_sales_on_farm_and_date',
              if_not_exists: true
  end
end
