class Farm < ApplicationRecord
  # Associations
  has_many :cows, dependent: :destroy
  has_many :production_records, dependent: :destroy
  has_many :sales_records, dependent: :destroy
  has_many :users, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :owner, presence: true
  validates :contact_phone, presence: true, format: { with: /\A[\+\-\s0-9]{10,20}\z/, message: "must be a valid phone number" }

  # Scopes
  scope :active, -> { where(status: 'active') }

  # Instance methods
  def total_cows
    cows.count
  end

  def active_cows
    cows.where(status: 'active').count
  end

  def today_production
    production_records.where(production_date: Date.current).sum(:total_production)
  end

  def monthly_production(month = Date.current.month, year = Date.current.year)
    production_records
      .where(production_date: Date.new(year, month, 1)..Date.new(year, month, -1))
      .sum(:total_production)
  end

  # User management methods
  def farm_owners
    users.where(role: 'farm_owner')
  end

  def farm_managers
    users.where(role: 'farm_manager')
  end

  def farm_workers
    users.where(role: 'farm_worker')
  end

  def all_staff
    users.active.order(:role, :first_name)
  end
end
