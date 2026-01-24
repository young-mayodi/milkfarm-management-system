class HealthRecord < ApplicationRecord
  belongs_to :cow

  # Validations
  validates :health_status, presence: true
  validates :recorded_at, presence: true
  validates :temperature, numericality: { greater_than: 35.0, less_than: 45.0 }, allow_nil: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true

  # Health status options
  HEALTH_STATUSES = %w[
    healthy
    sick
    injured
    recovering
    quarantine
    pregnant
    in_heat
    dry_period
    critical
  ].freeze

  validates :health_status, inclusion: { in: HEALTH_STATUSES }

  # Scopes
  scope :recent, -> { where(recorded_at: 30.days.ago..Time.current) }
  scope :by_status, ->(status) { where(health_status: status) }
  scope :with_temperature, -> { where.not(temperature: nil) }
  scope :with_weight, -> { where.not(weight: nil) }
  scope :sick_animals, -> { where(health_status: %w[sick injured critical quarantine]) }
  scope :healthy_animals, -> { where(health_status: %w[healthy recovering]) }

  # Instance methods
  def temperature_celsius
    temperature
  end

  def temperature_fahrenheit
    return nil unless temperature
    (temperature * 9.0 / 5.0) + 32
  end

  def is_abnormal_temperature?
    return false unless temperature
    temperature < 38.0 || temperature > 39.5
  end

  def requires_attention?
    health_status.in?(%w[sick injured critical quarantine]) || is_abnormal_temperature?
  end

  def days_since_recorded
    return 0 unless recorded_at
    (Time.current - recorded_at).to_i / 1.day
  end
end
