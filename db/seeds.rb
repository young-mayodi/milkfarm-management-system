# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
puts "Clearing existing data..."
User.destroy_all
ProductionRecord.destroy_all
SalesRecord.destroy_all
Cow.destroy_all
Farm.destroy_all

# Create sample farms
puts "Creating farms..."
bama_farm = Farm.create!(
  name: "BAMA DAIRY FARM",
  owner: "Bama Farm Owner", 
  location: "Kiambu County, Kenya",
  contact_phone: "+254-700-123456"
)

green_valley = Farm.create!(
  name: "Green Valley Dairy",
  owner: "John Kamau",
  location: "Nakuru County, Kenya", 
  contact_phone: "+254-722-987654"
)

puts "Creating cows..."
# Create cows for Bama Farm (matching the original record)
bama_cows = [
  { name: "KOKWET", tag_number: "001", breed: "Friesian", age: 5, group_name: "Group 1", status: "active" },
  { name: "Jomo 6", tag_number: "002", breed: "Holstein", age: 4, group_name: "Group 1", status: "active" },
  { name: "SILO 2", tag_number: "003", breed: "Jersey", age: 6, group_name: "Group 2", status: "active" },
  { name: "BAHATI", tag_number: "004", breed: "Friesian", age: 3, group_name: "Group 2", status: "active" },
  { name: "NAVASHA 1", tag_number: "005", breed: "Holstein", age: 7, group_name: "Group 2", status: "active" },
  { name: "TINDIRET 10", tag_number: "006", breed: "Crossbred", age: 4, group_name: "Group 1", status: "active" },
  { name: "LELGINA 1", tag_number: "007", breed: "Jersey", age: 5, group_name: "Group 1", status: "active" },
  { name: "LUGARI 5", tag_number: "008", breed: "Friesian", age: 6, group_name: "Group 1", status: "active" },
  { name: "TINDIRET 11", tag_number: "009", breed: "Holstein", age: 3, group_name: "Group 1", status: "active" },
  { name: "LUGARI 4", tag_number: "010", breed: "Jersey", age: 4, group_name: "Group 1", status: "active" },
  { name: "SILO 5", tag_number: "011", breed: "Friesian", age: 5, group_name: "Group 3", status: "active" },
  { name: "CHEPTERIT", tag_number: "012", breed: "Holstein", age: 6, group_name: "Group 3", status: "active" },
  { name: "LUGARI 8", tag_number: "013", breed: "Jersey", age: 4, group_name: "Group 3", status: "active" },
  { name: "CHELAA 1", tag_number: "014", breed: "Crossbred", age: 7, group_name: "Group 3", status: "active" },
  { name: "Silo 3", tag_number: "015", breed: "Friesian", age: 5, group_name: "Group 3", status: "active" },
  { name: "MERU 1", tag_number: "016", breed: "Holstein", age: 3, group_name: "Group 4", status: "active" },
  { name: "MERU 8", tag_number: "017", breed: "Jersey", age: 4, group_name: "Group 4", status: "active" },
  { name: "LAGOS", tag_number: "018", breed: "Friesian", age: 6, group_name: "Group 4", status: "active" },
  { name: "CHELEL 1", tag_number: "019", breed: "Holstein", age: 5, group_name: "Group 4", status: "active" },
  { name: "CHELEL 2", tag_number: "020", breed: "Jersey", age: 4, group_name: "Group 4", status: "active" }
]

bama_cows.each do |cow_data|
  bama_farm.cows.create!(cow_data)
end

# Create some cows for Green Valley
green_valley_cows = [
  { name: "Dairy Queen", tag_number: "GV001", breed: "Holstein", age: 4, group_name: "Group 1", status: "active" },
  { name: "Milk Star", tag_number: "GV002", breed: "Jersey", age: 5, group_name: "Group 1", status: "active" },
  { name: "Bessie", tag_number: "GV003", breed: "Friesian", age: 6, group_name: "Group 2", status: "active" },
  { name: "Sunshine", tag_number: "GV004", breed: "Crossbred", age: 3, group_name: "Group 2", status: "pregnant" },
  { name: "Moonbeam", tag_number: "GV005", breed: "Holstein", age: 7, group_name: "Group 1", status: "active" }
]

green_valley_cows.each do |cow_data|
  green_valley.cows.create!(cow_data)
end

puts "Creating production records..."
# Create production records for the last 90 days (more data for charts)
start_date = 90.days.ago.to_date
end_date = Date.current

(start_date..end_date).each do |date|
  # Skip some days randomly to simulate real data, but less skipping for more data
  next if rand(20) < 1 # Skip only about 5% of days randomly
  
  Farm.all.each do |farm|
    farm.cows.active.each do |cow|
      # Skip fewer cows on fewer days for more comprehensive data
      next if rand(20) < 1 # Skip only about 5% of cow-days
      
      # Generate realistic production data based on cow breed
      base_production = case cow.breed
                       when 'Holstein' then 25
                       when 'Friesian' then 23  
                       when 'Jersey' then 18
                       when 'Crossbred' then 15
                       else 12
                       end
      
      # Add some randomness (-20% to +30%) with seasonal variation
      seasonal_factor = 1 + 0.1 * Math.sin(2 * Math::PI * date.yday / 365.0)
      variation = 1 + (rand - 0.5) * 0.5
      daily_total = (base_production * variation * seasonal_factor).round(1)
      
      # Distribute across three milkings (morning largest, evening second, noon smallest)
      morning = (daily_total * (0.45 + rand * 0.1)).round(1)
      evening = (daily_total * (0.35 + rand * 0.1)).round(1) 
      noon = (daily_total - morning - evening).round(1)
      noon = [noon, 0].max # Ensure non-negative
      
      ProductionRecord.create!(
        cow: cow,
        farm: farm,
        production_date: date,
        morning_production: morning,
        noon_production: noon,
        evening_production: evening
      )
    end
  end
end

puts "Creating sales records..."
# Create comprehensive sales records
(start_date..end_date).each do |date|
  # Skip fewer sales days for better chart data
  next if rand(10) < 2 # Skip some days but less frequently
  
  Farm.all.each do |farm|
    daily_production = ProductionRecord.daily_farm_total(farm, date)
    next if daily_production == 0
    
    # Sell 80-95% of production
    milk_sold = (daily_production * (0.8 + rand * 0.15)).round(1)
    price_per_liter = 45 + rand * 10 # KES 45-55 per liter
    total_amount = (milk_sold * price_per_liter).round(0)
    
    # Split between cash and M-Pesa (60-40 to 40-60)
    cash_percentage = 0.4 + rand * 0.2
    cash_sales = (total_amount * cash_percentage).round(0)
    mpesa_sales = total_amount - cash_sales
    
    buyers = ["Local Dairy Co-op", "Brookside Dairy", "KCC", "Direct Sales", "Local Market"]
    
    SalesRecord.create!(
      farm: farm,
      sale_date: date,
      milk_sold: milk_sold,
      cash_sales: cash_sales,
      mpesa_sales: mpesa_sales,
      buyer: buyers.sample
    )
  end
end

# Create users for each farm
puts "Creating users..."

# Bama Farm users
bama_farm.users.create!([
  {
    email: "owner@bamafarm.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "John",
    last_name: "Bama",
    role: "farm_owner",
    phone: "+254-700-123456"
  },
  {
    email: "manager@bamafarm.com", 
    password: "password123",
    password_confirmation: "password123",
    first_name: "Mary",
    last_name: "Wanjiku",
    role: "farm_manager",
    phone: "+254-722-555777"
  },
  {
    email: "worker1@bamafarm.com",
    password: "password123", 
    password_confirmation: "password123",
    first_name: "Peter",
    last_name: "Kipchoge",
    role: "farm_worker",
    phone: "+254-733-444555"
  },
  {
    email: "vet@bamafarm.com",
    password: "password123",
    password_confirmation: "password123", 
    first_name: "Dr. Sarah",
    last_name: "Muthoni",
    role: "veterinarian",
    phone: "+254-711-333444"
  }
])

# Green Valley Farm users
green_valley.users.create!([
  {
    email: "kamau@greenvalley.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "John",
    last_name: "Kamau", 
    role: "farm_owner",
    phone: "+254-722-987654"
  },
  {
    email: "manager@greenvalley.com",
    password: "password123",
    password_confirmation: "password123", 
    first_name: "Grace",
    last_name: "Njeri",
    role: "farm_manager",
    phone: "+254-700-111222"
  }
])

puts "Seed data created successfully!"
puts "Created:"
puts "- #{Farm.count} farms"
puts "- #{Cow.count} cows"  
puts "- #{ProductionRecord.count} production records"
puts "- #{SalesRecord.count} sales records"
puts "- #{User.count} users"
puts ""
puts "Sample login credentials:"
puts "Bama Farm Owner: owner@bamafarm.com / password123"
puts "Green Valley Owner: kamau@greenvalley.com / password123"
