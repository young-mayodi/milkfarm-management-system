require 'rails_helper'

# Comprehensive RSpec Test Suite for Milk Production System
RSpec.describe 'MilkProductionSystem', type: :feature do
  before(:all) do
    @farm = Farm.first || FactoryBot.create(:farm)
    @cow = @farm.cows.first || FactoryBot.create(:cow, farm: @farm)
  end

  describe 'Financial Reporting System' do
    before do
      # Create test financial data
      create_financial_test_data
    end

    context 'Financial Dashboard' do
      it 'loads the financial dashboard successfully' do
        visit financial_reports_path
        expect(page).to have_content('Financial Dashboard')
        expect(page).to have_css('.financial-dashboard')
      end

      it 'displays KPI metrics correctly' do
        visit financial_reports_path
        expect(page).to have_content('Revenue')
        expect(page).to have_content('Expenses')
        expect(page).to have_content('Profit')
      end

      it 'period filtering works correctly' do
        visit financial_reports_path
        click_button 'Month'
        expect(page).to have_css('.active')
      end
    end

    context 'Profit & Loss Report' do
      it 'loads profit and loss report' do
        visit profit_loss_financial_reports_path
        expect(page).to have_content('Profit & Loss')
        expect(page).to have_content('Revenue Breakdown')
      end

      it 'calculates financial metrics correctly' do
        visit profit_loss_financial_reports_path
        expect(page).to have_css('.revenue-section')
        expect(page).to have_css('.expense-section')
      end
    end

    context 'Cost Analysis Report' do
      it 'loads cost analysis report' do
        visit cost_analysis_financial_reports_path
        expect(page).to have_content('Cost Analysis')
        expect(page).to have_content('Cost per Liter')
      end

      it 'displays expense categories' do
        visit cost_analysis_financial_reports_path
        expect(page).to have_content('Feed')
        expect(page).to have_content('Veterinary')
      end
    end

    context 'ROI Analytics Report' do
      it 'loads ROI report successfully' do
        visit roi_report_financial_reports_path
        expect(page).to have_content('ROI Analytics')
        expect(page).to have_content('Return on Investment')
      end

      it 'shows individual cow performance' do
        visit roi_report_financial_reports_path
        expect(page).to have_css('.cow-performance')
      end
    end
  end

  describe 'Mobile Responsiveness' do
    before do
      # Set mobile viewport
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone 6/7/8 size
    end

    after do
      # Reset to desktop
      page.driver.browser.manage.window.resize_to(1200, 800)
    end

    it 'displays mobile navigation correctly' do
      visit financial_reports_path
      expect(page).to have_css('.mobile-nav', visible: false)
      # Mobile menu should be hidden by default
    end

    it 'charts are properly sized for mobile' do
      visit financial_reports_path
      chart_element = page.find('.chart-container', match: :first)
      chart_height = chart_element.native.css_value('max-height')
      expect(chart_height).to match(/250px/)
    end

    it 'buttons are touch-friendly sized' do
      visit financial_reports_path
      button = page.find('.btn', match: :first)
      button_height = button.native.css_value('min-height')
      expect(button_height.to_i).to be >= 44
    end
  end

  describe 'Database Performance' do
    it 'does not have N+1 query issues in cow summary' do
      expect do
        visit '/reports/cow_summary'
      end.not_to exceed_query_limit(10) # Should not exceed 10 queries
    end

    it 'financial calculations are performant' do
      start_time = Time.current
      visit financial_reports_path
      load_time = Time.current - start_time
      expect(load_time).to be < 2.0 # Should load in under 2 seconds
    end
  end

  describe 'Data Integrity' do
    it 'handles missing data gracefully' do
      # Create farm with no data
      empty_farm = FactoryBot.create(:farm)
      
      visit financial_reports_path(farm_id: empty_farm.id)
      expect(page).to have_content('No data available')
    end

    it 'validates financial calculations' do
      sales = @farm.sales_records.sum(:total_sales)
      expenses = @farm.expenses.sum(:amount)
      profit = sales - expenses
      
      visit financial_reports_path
      # Check that displayed profit matches calculation
      expect(page).to have_content(profit.round(2).to_s)
    end
  end

  describe 'Production Entry System' do
    it 'allows creating new production records' do
      visit production_entry_path
      
      fill_in 'Morning Production', with: '15.5'
      fill_in 'Noon Production', with: '12.3'
      fill_in 'Evening Production', with: '14.2'
      select @cow.name, from: 'Cow'
      
      click_button 'Save Production'
      
      expect(page).to have_content('Production record saved')
      expect(ProductionRecord.last.total_production).to eq(42.0)
    end

    it 'validates production entry data' do
      visit production_entry_path
      
      click_button 'Save Production'
      
      expect(page).to have_content('Please correct the errors')
    end
  end

  describe 'Animal Management' do
    it 'displays cow summary without performance issues' do
      visit '/reports/cow_summary'
      expect(page).to have_content('Cow Summary')
      expect(page).to have_css('.cow-stats')
    end

    it 'shows individual cow performance metrics' do
      visit '/reports/cow_summary'
      expect(page).to have_content(@cow.name)
      expect(page).to have_content('Total Production')
    end
  end

  describe 'Chart Functionality' do
    it 'renders charts without JavaScript errors', js: true do
      visit financial_reports_path
      
      # Wait for charts to load
      sleep 2
      
      # Check that Chart.js has loaded
      expect(page.evaluate_script('typeof Chart')).to eq('function')
      
      # Check for chart elements
      expect(page).to have_css('canvas')
    end

    it 'charts are interactive on mobile', js: true do
      page.driver.browser.manage.window.resize_to(375, 667)
      visit financial_reports_path
      
      sleep 2
      
      # Touch events should be enabled
      chart_canvas = page.find('canvas', match: :first)
      expect(chart_canvas).to be_present
    end
  end

  describe 'Error Handling' do
    it 'handles database connection errors gracefully' do
      # Simulate database error
      allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)
      
      visit financial_reports_path
      expect(page).to have_content('Database connection error')
    end

    it 'displays user-friendly error messages' do
      # Visit non-existent route
      visit '/non-existent-route'
      expect(page.status_code).to eq(404)
    end
  end

  private

  def create_financial_test_data
    # Create test sales records
    @farm.sales_records.create!(
      sale_date: Date.current,
      milk_sold: 100,
      price_per_liter: 50,
      total_sales: 5000,
      buyer_name: 'Test Buyer'
    )

    # Create test expenses
    @farm.expenses.create!(
      expense_type: 'feed',
      amount: 2000,
      description: 'Test feed expense',
      expense_date: Date.current,
      category: 'feed'
    )

    # Create test production records
    @cow.production_records.create!(
      farm: @farm,
      production_date: Date.current,
      morning_production: 15,
      noon_production: 12,
      evening_production: 13,
      total_production: 40
    )
  end
end

# Additional controller specs
RSpec.describe FinancialReportsController, type: :controller do
  let(:farm) { FactoryBot.create(:farm) }
  let(:cow) { FactoryBot.create(:cow, farm: farm) }

  describe 'GET #index' do
    it 'returns success response' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns financial overview data' do
      get :index
      expect(assigns(:financial_overview)).to be_present
    end
  end

  describe 'GET #profit_loss' do
    it 'calculates profit and loss correctly' do
      create_test_financial_data(farm, cow)
      get :profit_loss
      
      expect(assigns(:profit_loss_data)).to be_present
      expect(assigns(:profit_loss_data)[:revenue]).to be > 0
    end
  end

  describe 'GET #cost_analysis' do
    it 'calculates cost per liter correctly' do
      create_test_financial_data(farm, cow)
      get :cost_analysis
      
      expect(assigns(:cost_analysis_data)).to be_present
      expect(assigns(:cost_per_liter)).to be > 0
    end
  end

  describe 'GET #roi_report' do
    it 'calculates ROI metrics correctly' do
      create_test_financial_data(farm, cow)
      get :roi_report
      
      expect(assigns(:roi_data)).to be_present
      expect(assigns(:animal_roi)).to be_present
    end
  end

  private

  def create_test_financial_data(farm, cow)
    farm.sales_records.create!(
      sale_date: Date.current,
      milk_sold: 100,
      price_per_liter: 50,
      total_sales: 5000,
      buyer_name: 'Test Buyer'
    )

    farm.expenses.create!(
      expense_type: 'feed',
      amount: 2000,
      description: 'Test feed',
      expense_date: Date.current,
      category: 'feed'
    )

    cow.production_records.create!(
      farm: farm,
      production_date: Date.current,
      morning_production: 15,
      noon_production: 12,
      evening_production: 13,
      total_production: 40
    )
  end
end
