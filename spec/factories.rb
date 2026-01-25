# FactoryBot factories for testing
# This file defines factories for creating test data

FactoryBot.define do
  factory :farm do
    name { "Test Farm #{rand(1000)}" }
    location { "Test Location" }
    farm_size { rand(50..500) }
    established_date { rand(1..10).years.ago }
    contact_number { "+254712345678" }
    owner_name { "Test Owner" }
  end

  factory :cow do
    association :farm
    name { "Test Cow #{rand(1000)}" }
    tag_number { "TC#{rand(1000..9999)}" }
    breed { %w[Holstein Friesian Jersey Ayrshire].sample }
    date_of_birth { rand(1..5).years.ago }
    health_status { 'healthy' }
    breeding_status { %w[open pregnant].sample }
    weight { rand(300..600) }
  end

  factory :production_record do
    association :cow
    association :farm
    production_date { Date.current }
    morning_production { rand(8.0..20.0).round(1) }
    noon_production { rand(6.0..15.0).round(1) }
    evening_production { rand(7.0..18.0).round(1) }

    before(:create) do |record|
      record.total_production = record.morning_production +
                               record.noon_production +
                               record.evening_production
    end
  end

  factory :sales_record do
    association :farm
    sale_date { Date.current }
    milk_sold { rand(50..500) }
    price_per_liter { rand(40..60) }
    buyer_name { "Test Buyer #{rand(100)}" }

    before(:create) do |record|
      record.total_sales = record.milk_sold * record.price_per_liter
    end
  end

  factory :expense do
    association :farm
    expense_type { %w[feed veterinary labor maintenance].sample }
    amount { rand(500..5000) }
    description { "Test expense for #{expense_type}" }
    expense_date { Date.current }
    category { expense_type }
  end

  # Factory for creating a complete farm with all associated data
  factory :farm_with_data, parent: :farm do
    after(:create) do |farm|
      # Create cows
      create_list(:cow, 3, farm: farm)

      # Create production records for each cow
      farm.cows.each do |cow|
        create_list(:production_record, 30, cow: cow, farm: farm,
                   production_date: rand(30.days.ago..Date.current))
      end

      # Create sales records
      create_list(:sales_record, 10, farm: farm,
                 sale_date: rand(30.days.ago..Date.current))

      # Create expenses
      create_list(:expense, 15, farm: farm,
                 expense_date: rand(30.days.ago..Date.current))
    end
  end
end
