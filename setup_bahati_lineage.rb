# Script to set up Bahati lineage
# Based on the user's diagram:
# BAHATI OLD -> BAHATI I -> [Bahati 2, Bahati 3]

begin
  bahati_old = Cow.find(208)  # BAHATI (004) - the ancestor
  bahati_2 = Cow.find(236)    # Bahati 2 (BM/4/C)

  puts 'Creating BAHATI I...'
  # Create BAHATI I as child of BAHATI OLD
  bahati_1 = Cow.find_or_create_by!(tag_number: 'BM/1/B') do |cow|
    cow.name = 'BAHATI I'
    cow.breed = bahati_old.breed
    cow.age = 5
    cow.farm_id = bahati_old.farm_id
    cow.status = 'active'
    cow.mother_id = bahati_old.id
    cow.birth_date = Date.new(2021, 1, 1)
  end
  puts "Created/Found BAHATI I (ID: #{bahati_1.id})"

  # Update Bahati 2 to be child of BAHATI I
  puts 'Updating Bahati 2 to be child of BAHATI I...'
  bahati_2.update!(mother_id: bahati_1.id)
  puts 'Updated Bahati 2'

  # Create Bahati 3 as sibling of Bahati 2
  puts 'Creating Bahati 3...'
  bahati_3 = Cow.find_or_create_by!(tag_number: 'BM/3/B') do |cow|
    cow.name = 'Bahati 3'
    cow.breed = bahati_1.breed
    cow.age = 2
    cow.farm_id = bahati_1.farm_id
    cow.status = 'active'
    cow.mother_id = bahati_1.id
    cow.birth_date = Date.new(2024, 1, 1)
  end
  puts "Created/Found Bahati 3 (ID: #{bahati_3.id})"

  puts "\nLineage created successfully!"
  puts "BAHATI OLD (#{bahati_old.id}) -> BAHATI I (#{bahati_1.id}) -> [Bahati 2 (#{bahati_2.id}), Bahati 3 (#{bahati_3.id})]"
  puts "\nYou can now view the lineage by clicking 'Family Tree' on any of these cows!"
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
end
