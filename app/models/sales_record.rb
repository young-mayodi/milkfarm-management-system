class SalesRecord < ApplicationRecord
  # Associations
  belongs_to :farm

  # Validations
  validates :sale_date, presence: true
  validates :milk_sold, presence: true, numericality: { greater_than: 0 }
  validates :cash_sales, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :mpesa_sales, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :buyer, presence: true

  # Callbacks
  before_save :calculate_total_sales

  # Scopes
  scope :for_date, ->(date) { where(sale_date: date) }
  scope :for_month, ->(month, year) { 
    where(sale_date: Date.new(year, month, 1)..Date.new(year, month, -1)) 
  }
  scope :recent, -> { order(sale_date: :desc) }

  # Class methods
  def self.daily_farm_total(farm, date)
    where(farm: farm, sale_date: date).sum(:total_sales)
  end

  def self.monthly_farm_total(farm, month = Date.current.month, year = Date.current.year)
    where(farm: farm)
      .where(sale_date: Date.new(year, month, 1)..Date.new(year, month, -1))
      .sum(:total_sales)
  end

  private

  def calculate_total_sales
    self.total_sales = (cash_sales || 0) + (mpesa_sales || 0)
  end
end
