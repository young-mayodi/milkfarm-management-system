class Admin::DataPopulationController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:populate_april_24]
  
  # POST /admin/populate_april_24
  def populate_april_24
    # Simple authentication - use an environment variable as a token
    provided_token = request.headers['X-Admin-Token'] || params[:token]
    expected_token = ENV['ADMIN_TOKEN'] || 'changeme123'
    
    unless provided_token == expected_token
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end

    # Run the rake task
    result = []
    record_date = Date.new(2025, 4, 24)
    
    farm = Farm.find_or_create_by!(name: "Bama Dairy Farm") do |f|
      f.location = "Kenya"
      f.size_acres = 100
    end

    result << "Farm: #{farm.name} (ID: #{farm.id})"

    production_data = [
      ["KOKWET", 9.8, 8.0, 9.0],
      ["Jema 3", 11.8, 8.5, 9.0],
      ["SILO 2", 8.1, 9.2, 6.2],
      ["BAHATI 1", 6.6, 5.0, 6.6],
      ["BAHATI 2", 7.0, 4.5, 6.1],
      ["TINDIRET 10", 10.5, 6.2, 4.9],
      ["ELEGNA 1", 8.6, 6.2, 9.9],
      ["LUGARI 5", 7.0, 6.2, 5.4],
      ["TINDIRET 1", 6.5, 5.5, 5.8],
      ["LUGARI 4", 8.2, 5.8, 4.9],
      ["SILO 5", 8.4, 4.5, 5.1],
      ["CHEPTERIT", 9.1, 5.5, 5.9],
      ["LUGARI 8", 7.5, 4.0, 5.8],
      ["CHELAA 1", 6.0, 4.2, 4.0],
      ["Sile 3", 9.5, 4.6, 8.5],
      ["MERU 1", 6.4, 0, 5.2],
      ["LAGOS", 10.2, 0, 0],
      ["CHELEI 1", 6.4, 0, 5.5],
    ]

    created_count = 0
    production_data.each do |cow_name, morning, noon, evening|
      cow = Cow.find_or_create_by!(name: cow_name, farm: farm) do |c|
        c.tag_number = "#{cow_name.upcase.gsub(/\s+/, '')}-#{rand(1000..9999)}"
        c.breed = "Holstein"
        c.date_of_birth = 3.years.ago
        c.status = "active"
      end
      
      total = (morning || 0) + (noon || 0) + (evening || 0)
      record = ProductionRecord.find_or_create_by!(
        cow: cow,
        farm: farm,
        production_date: record_date
      ) do |r|
        r.morning_production = morning || 0
        r.noon_production = noon || 0
        r.evening_production = evening || 0
        r.total_production = total
      end
      
      created_count += 1 if record.persisted?
    end

    result << "Created #{created_count} production records for #{record_date}"

    # Backfill
    start_date = Date.new(2025, 4, 25)
    end_date = Date.today
    backfill_count = 0
    
    farm.cows.where(status: "active").find_each do |cow|
      existing_records = ProductionRecord.where(cow: cow)
      next if existing_records.empty?
      
      avg_morning = existing_records.average(:morning_production).to_f.round(1)
      avg_noon = existing_records.average(:noon_production).to_f.round(1)
      avg_evening = existing_records.average(:evening_production).to_f.round(1)
      avg_total = (avg_morning + avg_noon + avg_evening).round(1)
      
      existing_dates = existing_records.pluck(:production_date).to_set
      (start_date..end_date).each do |date|
        next if existing_dates.include?(date)
        
        ProductionRecord.create!(
          cow: cow,
          farm: farm,
          production_date: date,
          morning_production: avg_morning,
          noon_production: avg_noon,
          evening_production: avg_evening,
          total_production: avg_total
        )
        backfill_count += 1
      end
    end

    result << "Backfilled #{backfill_count} records from #{start_date} to #{end_date}"
    result << "Total production records: #{ProductionRecord.where(farm: farm).count}"

    render json: { success: true, message: result.join("\n") }
  rescue => e
    render json: { error: e.message, backtrace: e.backtrace[0..5] }, status: :internal_server_error
  end
end
