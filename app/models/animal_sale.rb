class AnimalSale < ApplicationRecord
  belongs_to :cow
  belongs_to :farm

  validates :sale_date, presence: true
  validates :sale_price, presence: true, numericality: { greater_than: 0 }
  validates :buyer, presence: true
  validates :animal_type, presence: true, inclusion: { in: %w[calf cow] }

  scope :calves, -> { where(animal_type: "calf") }
  scope :cows, -> { where(animal_type: "cow") }
  scope :recent, -> { order(sale_date: :desc) }
  scope :for_month, ->(month, year) {
    where(sale_date: Date.new(year, month, 1)..Date.new(year, month, -1))
  }

  def self.monthly_revenue(farm, month = Date.current.month, year = Date.current.year)
    where(farm: farm)
      .for_month(month, year)
      .sum(:sale_price)
  end

  def self.total_animals_sold(farm, animal_type = nil)
    query = where(farm: farm)
    query = query.where(animal_type: animal_type) if animal_type
    query.count
  end
end
