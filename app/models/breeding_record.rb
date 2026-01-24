class BreedingRecord < ApplicationRecord
  belongs_to :cow

  # Validations
  validates :breeding_date, presence: true
  validates :breeding_method, presence: true
  validates :breeding_status, presence: true
  validate :expected_due_date_after_breeding_date
  validate :actual_due_date_after_breeding_date, if: :actual_due_date?

  # Breeding methods
  BREEDING_METHODS = %w[
    artificial_insemination
    natural_service
    embryo_transfer
    synchronized_breeding
  ].freeze

  # Breeding statuses
  BREEDING_STATUSES = %w[
    attempted
    confirmed
    failed
    aborted
    completed
    pending_confirmation
  ].freeze

  validates :breeding_method, inclusion: { in: BREEDING_METHODS }
  validates :breeding_status, inclusion: { in: BREEDING_STATUSES }

  # Scopes
  scope :recent, -> { where(breeding_date: 1.year.ago..Time.current) }
  scope :by_method, ->(method) { where(breeding_method: method) }
  scope :by_status, ->(status) { where(breeding_status: status) }
  scope :confirmed, -> { where(breeding_status: "confirmed") }
  scope :pending, -> { where(breeding_status: "pending_confirmation") }
  scope :due_soon, -> { where(expected_due_date: Date.current..1.month.from_now) }
  scope :overdue, -> { where("expected_due_date < ? AND breeding_status = ?", Date.current, "confirmed") }

  # Callbacks
  before_save :calculate_expected_due_date, if: :breeding_date_changed?

  # Instance methods
  def gestation_period_days
    283 # Average gestation period for cattle
  end

  def calculate_expected_due_date
    self.expected_due_date = breeding_date + gestation_period_days.days if breeding_date
  end

  def days_to_due_date
    return nil unless expected_due_date
    (expected_due_date - Date.current).to_i
  end

  def is_overdue?
    expected_due_date && Date.current > expected_due_date && breeding_status == "confirmed"
  end

  def is_due_soon?
    expected_due_date && days_to_due_date && days_to_due_date <= 30 && days_to_due_date >= 0
  end

  def gestation_stage
    return nil unless breeding_status == "confirmed" && breeding_date

    days_pregnant = (Date.current - breeding_date).to_i
    case days_pregnant
    when 0..90
      "first_trimester"
    when 91..180
      "second_trimester"
    when 181..283
      "third_trimester"
    else
      "overdue"
    end
  end

  private

  def expected_due_date_after_breeding_date
    return unless breeding_date && expected_due_date
    errors.add(:expected_due_date, "must be after breeding date") if expected_due_date <= breeding_date
  end

  def actual_due_date_after_breeding_date
    return unless breeding_date && actual_due_date
    errors.add(:actual_due_date, "must be after breeding date") if actual_due_date <= breeding_date
  end
end
