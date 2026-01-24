class VaccinationRecord < ApplicationRecord
  belongs_to :cow

  # Validations
  validates :vaccine_name, presence: true
  validates :vaccination_date, presence: true
  validates :administered_by, presence: true
  validate :next_due_date_after_vaccination_date

  # Common vaccine types
  VACCINE_TYPES = [
    "BVD (Bovine Viral Diarrhea)",
    "IBR (Infectious Bovine Rhinotracheitis)",
    "PI3 (Parainfluenza 3)",
    "BRSV (Bovine Respiratory Syncytial Virus)",
    "Blackleg (Clostridium chauvoei)",
    "Brucellosis",
    "Leptospirosis",
    "Anthrax",
    "Foot and Mouth Disease",
    "Mastitis Prevention",
    "Rabies",
    "Tetanus",
    "Other"
  ].freeze

  # Scopes
  scope :recent, -> { where(vaccination_date: 1.year.ago..Time.current) }
  scope :by_vaccine, ->(vaccine) { where(vaccine_name: vaccine) }
  scope :due_soon, -> { where(next_due_date: Date.current..1.month.from_now) }
  scope :overdue, -> { where("next_due_date < ?", Date.current) }
  scope :administered_by, ->(person) { where(administered_by: person) }

  # Callbacks
  before_save :calculate_next_due_date, if: :vaccination_date_changed?

  # Instance methods
  def vaccine_interval_months
    case vaccine_name.downcase
    when /bvd|ibr|pi3|brsv/
      12 # Annual vaccines
    when /blackleg/
      12 # Annual
    when /brucellosis/
      nil # Usually once in lifetime
    when /leptospirosis/
      6 # Bi-annual
    when /mastitis/
      6 # Bi-annual
    when /rabies/
      36 # Every 3 years
    when /tetanus/
      12 # Annual
    else
      12 # Default to annual
    end
  end

  def calculate_next_due_date
    interval = vaccine_interval_months
    self.next_due_date = vaccination_date + interval.months if vaccination_date && interval
  end

  def days_until_due
    return nil unless next_due_date
    (next_due_date - Date.current).to_i
  end

  def is_overdue?
    next_due_date && Date.current > next_due_date
  end

  def is_due_soon?
    next_due_date && days_until_due && days_until_due <= 30 && days_until_due >= 0
  end

  def urgency_level
    return "unknown" unless next_due_date

    days = days_until_due
    case days
    when -Float::INFINITY..-1
      "overdue"
    when 0..7
      "critical"
    when 8..30
      "upcoming"
    else
      "scheduled"
    end
  end

  def urgency_color
    case urgency_level
    when "overdue"
      "danger"
    when "critical"
      "warning"
    when "upcoming"
      "info"
    else
      "success"
    end
  end

  private

  def next_due_date_after_vaccination_date
    return unless vaccination_date && next_due_date
    errors.add(:next_due_date, "must be after vaccination date") if next_due_date <= vaccination_date
  end
end
