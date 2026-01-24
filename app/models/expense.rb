class Expense < ApplicationRecord
  belongs_to :farm

  # Validations
  validates :expense_type, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true
  validates :category, presence: true

  # Categories
  CATEGORIES = %w[
    feed
    veterinary
    labor
    maintenance
    utilities
    transport
    equipment
    breeding
    insurance
    other
  ].freeze

  validates :category, inclusion: { in: CATEGORIES }

  # Scopes
  scope :for_date_range, ->(start_date, end_date) { where(expense_date: start_date..end_date) }
  scope :by_category, ->(category) { where(category: category) }
  scope :for_month, ->(month, year) {
    where(expense_date: Date.new(year, month, 1)..Date.new(year, month, -1))
  }
  scope :recent, -> { order(expense_date: :desc) }

  # Class methods
  def self.total_for_period(farm, date_range)
    where(farm: farm, expense_date: date_range).sum(:amount)
  end

  def self.breakdown_by_category(farm, date_range)
    where(farm: farm, expense_date: date_range)
      .group(:category)
      .sum(:amount)
      .transform_values { |amount| amount.to_f.round(2) }
  end

  def self.monthly_trend(farm, months_back: 6)
    trend_data = {}

    (0..months_back-1).each do |month_offset|
      date = month_offset.months.ago
      month_start = date.beginning_of_month
      month_end = date.end_of_month

      monthly_total = where(farm: farm, expense_date: month_start..month_end).sum(:amount)
      trend_data[month_start] = monthly_total.to_f.round(2)
    end

    trend_data
  end
end
