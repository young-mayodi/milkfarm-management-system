namespace :data do
  desc "Populate calves from spreadsheet data"
  task populate_calves: :environment do
    # Data from the spreadsheet
    calves_data = [
      ["kokwet bull", "BM/12/D", "8/Dec/2025", "12/Jan/2026", "19/Jan/2026", 53.5, 57, 7, 3.5, 0.50],
      ["LUGARI 7", "BM/11/D", "12/Nov/2025", "12/Jan/2026", "19/Jan/2026", 58.5, 64, 7, 5.5, 0.79],
      ["CHEPTERIT BULL", "BM/11/D", "18/Nov/2025", "12/Jan/2026", "19/Jan/2026", 61.5, 66, 7, 4.5, 0.64],
      ["JOMO BULL", "BM/11/D", "21/Nov/2025", "12/Jan/2026", "19/Jan/2026", 51.5, 56, 7, 4.5, 0.64],
      ["NAIVASHABVUL", "BM/10/D", "3/Oct/2025", "12/Jan/2026", "19/Jan/2026", 81, 85, 7, 4, 0.57],
      ["TINDIRET4", "BM/10/D", "5/Oct/2025", "12/Jan/2026", "19/Jan/2026", 108.5, 114, 7, 5.5, 0.79],
      ["BAHATI3", "BM/10/D", "3/Oct/2025", "12/Jan/2026", "19/Jan/2026", 97, 101, 7, 4, 0.57],
      ["SILO8", "BM/10/D", "5/Oct/2025", "12/Jan/2026", "19/Jan/2026", 90.5, 95.5, 7, 5, 0.71],
      ["MERU3", "BM/3/D", "23/Mar/2025", "12/Jan/2026", "19/Jan/2026", 159, 164, 7, 5, 0.71],
      ["CHELAABULL", "BM/3/D", "2/Mar/2025", "12/Jan/2026", "19/Jan/2026", 210, 213, 7, 3, 0.43],
      ["NAIVASHA10", "BM/10/C", "8/Oct/2025", "12/Jan/2026", "19/Jan/2026", 170, 174, 7, 4, 0.57],
      ["NAIVASHA2", "BM/7/C", "19/Jul/2025", "12/Jan/2026", "19/Jan/2026", 302.5, 307, 7, 4.5, 0.64],
      ["BAHATI2", "BM/4/C", "23/Apr/2025", "12/Jan/2026", "19/Jan/2026", 385, 399, 7, 14, 2.00],
      ["TINDIRET2", "BM/4/C", "24/Apr/2025", "12/Jan/2026", "19/Jan/2026", 338, 351, 7, 13, 1.86],
      ["SILO6", "BM/7/C", "12/Jul/2025", "12/Jan/2026", "19/Jan/2026", 298, 305, 7, 7, 1.00],
      ["LUGARI6", "BM/7/C", "27/Jul/2025", "12/Jan/2026", "19/Jan/2026", 327.5, 344, 7, 16.5, 2.36],
      ["SILO7", "BM/7/C", "26/Jul/2025", "12/Jan/2026", "19/Jan/2026", 270, 278, 7, 8, 1.14],
      ["LABAN", "BM/1/D", nil, "12/Jan/2026", "19/Jan/2026", 247, 230, 7, -17, -2.43],
      ["SILOBULL", "BM/8/D", "20/Aug/2025", "12/Jan/2026", "19/Jan/2026", 118.5, 121.5, 7, 3, 0.43]
    ]

    def parse_date(date_str)
      return nil if date_str.nil? || date_str.empty?
      begin
        Date.strptime(date_str, "%d/%b/%Y")
      rescue
        begin
          Date.strptime(date_str, "%d/%m/%Y")
        rescue
          puts "Warning: Could not parse date '#{date_str}'"
          nil
        end
      end
    end

    def calculate_age_from_birth_date(birth_date)
      return 6 if birth_date.nil? # Default age if no birth date
      
      months_old = ((Date.current - birth_date) / 30.44).to_i # Average days per month
      months_old = 1 if months_old < 1 # Minimum 1 month
      months_old
    end

    def determine_breed(tag_number)
      # Based on tag patterns, assign breeds
      case tag_number
      when /BM.*\/D$/
        "Holstein" # Dairy bulls
      when /BM.*\/C$/
        "Jersey" # Could be different breed for cows
      else
        "Crossbred"
      end
    end

    # Get or create farm (assuming we have a farm to assign calves to)
    farm = Farm.first
    unless farm
      puts "No farm found! Creating a default farm..."
      farm = Farm.create!(
        name: "Bama Farm",
        location: "Kenya",
        contact_info: "Farm Owner"
      )
    end

    puts "🐄 Starting calf population from spreadsheet data..."
    puts "📍 Using farm: #{farm.name} (ID: #{farm.id})"
    puts "="*60

    created_count = 0
    updated_count = 0
    error_count = 0

    calves_data.each_with_index do |row, index|
      name, tag_number, birth_date_str, first_weight_date_str, second_weight_date_str, 
      prev_weight, current_weight, days_between, weight_gain, daily_gain = row
      
      puts "\n#{index + 1}. Processing: #{name} (#{tag_number})"
      
      begin
        # Parse dates
        birth_date = parse_date(birth_date_str)
        
        # Calculate age in months
        age = calculate_age_from_birth_date(birth_date)
        
        # Determine breed from tag
        breed = determine_breed(tag_number)
        
        # Check if calf already exists
        existing_calf = Cow.find_by(tag_number: tag_number, farm: farm)
        
        calf_attributes = {
          name: name.titleize,
          tag_number: tag_number,
          farm: farm,
          age: age,
          breed: breed,
          status: "active",
          birth_date: birth_date,
          current_weight: current_weight,
          prev_weight: prev_weight,
          weight_gain: weight_gain,
          avg_daily_gain: daily_gain
        }
        
        if existing_calf
          existing_calf.update!(calf_attributes)
          puts "   ✅ Updated existing calf: #{existing_calf.name}"
          updated_count += 1
        else
          calf = Cow.create!(calf_attributes)
          puts "   ✨ Created new calf: #{calf.name}"
          puts "      - Age: #{calf.age} months"
          puts "      - Breed: #{calf.breed}"
          puts "      - Current Weight: #{calf.current_weight} kg"
          puts "      - Daily Gain: #{calf.avg_daily_gain} kg/day"
          created_count += 1
        end
        
      rescue => e
        puts "   ❌ Error processing #{name}: #{e.message}"
        error_count += 1
        next
      end
    end

    puts "\n" + "="*60
    puts "🎉 CALF POPULATION COMPLETE!"
    puts "📊 Summary:"
    puts "   ✨ Created: #{created_count} new calves"
    puts "   ✅ Updated: #{updated_count} existing calves"
    puts "   ❌ Errors: #{error_count} failed records"
    puts "   📈 Total processed: #{created_count + updated_count + error_count} records"

    # Display some statistics
    total_calves = Cow.calves.count
    avg_weight = Cow.calves.where.not(current_weight: nil).average(:current_weight)
    avg_daily_gain = Cow.calves.where.not(avg_daily_gain: nil).average(:avg_daily_gain)

    puts "\n🐄 Farm Statistics:"
    puts "   Total calves: #{total_calves}"
    puts "   Average weight: #{avg_weight&.round(1) || 'N/A'} kg"
    puts "   Average daily gain: #{avg_daily_gain&.round(3) || 'N/A'} kg/day"

    puts "\n📋 Calves by breed:"
    Cow.calves.group(:breed).count.each do |breed, count|
      puts "   #{breed}: #{count} calves"
    end

    puts "\n✅ Script completed successfully!"
  end
end
