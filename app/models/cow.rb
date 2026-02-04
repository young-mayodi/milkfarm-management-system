class Cow < ApplicationRecord
  # Associations
  belongs_to :farm, counter_cache: true
  belongs_to :mother, class_name: "Cow", optional: true
  belongs_to :sire, class_name: "Cow", optional: true
  has_many :calves, class_name: "Cow", foreign_key: "mother_id", dependent: :nullify
  has_many :offspring_as_sire, class_name: "Cow", foreign_key: "sire_id", dependent: :nullify
  has_many :production_records, dependent: :destroy, counter_cache: true
  has_one :animal_sale, dependent: :destroy

  # Advanced Animal Management Associations
  has_many :health_records, dependent: :destroy, counter_cache: true
  has_many :breeding_records, dependent: :destroy, counter_cache: true
  has_many :vaccination_records, dependent: :destroy, counter_cache: true

  # Validations
  validates :name, presence: true
  validates :tag_number, presence: true, uniqueness: { scope: :farm_id }
  validates :breed, presence: true
  validates :age, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[active inactive pregnant sick healthy sold deceased graduated_to_dairy] }

  # Validations for weight and growth data
  validates :current_weight, numericality: { greater_than: 0 }, allow_nil: true
  validates :prev_weight, numericality: { greater_than: 0 }, allow_nil: true
  validates :weight_gain, numericality: true, allow_nil: true
  validates :avg_daily_gain, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Callbacks for maintaining active_cows_count
  after_create :increment_active_count_if_needed
  after_update :update_active_count_if_status_changed
  after_destroy :decrement_active_count_if_needed

  # Scopes - optimized for database performance
  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :active, -> { not_deleted.where(status: "active") }
  scope :by_group, ->(group) { where(group_name: group) }
  scope :adult_cows, -> { not_deleted.where("cows.age >= ? AND cows.mother_id IS NULL", 2) }
  scope :calves, -> { not_deleted.where("cows.age < ? OR cows.mother_id IS NOT NULL", 2) }
  scope :with_mother, -> { not_deleted.where.not(mother_id: nil) }
  scope :sold, -> { not_deleted.where(status: "sold") }
  scope :deceased, -> { not_deleted.where(status: "deceased") }
  scope :graduated, -> { not_deleted.where(status: "graduated_to_dairy") }
  scope :ready_for_dairy, -> { calves.where("age >= 1.5").where("current_weight >= 80") }
  scope :can_be_milked, -> { not_deleted.where(status: [ "active", "graduated_to_dairy" ]).where("age >= 1.5") }
  scope :milkable_animals, -> { not_deleted.where(status: [ "active", "graduated_to_dairy" ]).where("age >= 1.5") }

  # Override default scope to exclude soft-deleted records
  default_scope -> { where(deleted_at: nil) }

  # Performance optimized scopes
  scope :with_farm_and_mother, -> { includes(:farm, :mother) }
  scope :with_recent_production, -> { includes(:production_records).where(production_records: { production_date: 1.week.ago..Date.current }) }
  scope :search_by_name_or_tag, ->(term) {
    where("cows.name ILIKE ? OR cows.tag_number ILIKE ?", "%#{term}%", "%#{term}%") if term.present?
  }

  # Instance methods
  def latest_production
    production_records.order(production_date: :desc).first
  end

  def total_production_for_date(date)
    production_records.find_by(production_date: date)&.total_production || 0
  end

  def average_daily_production(days = 30)
    recent_records = production_records
      .where(production_date: (Date.current - days.days)..Date.current)

    return 0 if recent_records.empty?

    recent_records.average(:total_production) || 0
  end

  def status_badge_class
    case status
    when "active" then "success"
    when "healthy" then "success"
    when "pregnant" then "info"
    when "sick" then "danger"
    when "inactive" then "secondary"
    when "sold" then "warning"
    when "deceased" then "dark"
    when "graduated_to_dairy" then "primary"
    else "light"
    end
  end

  def is_calf?
    age < 2 || mother_id.present?
  end

  # Calf-specific methods
  def age_in_days
    return nil unless birth_date
    (Date.current - birth_date).to_i
  end

  def age_in_months
    return nil unless birth_date
    age_in_days / 30.0
  end

  def growth_rate_category
    return "N/A" unless avg_daily_gain

    case avg_daily_gain
    when 0..0.4
      "Slow Growth"
    when 0.4..0.7
      "Normal Growth"
    when 0.7..1.0
      "Fast Growth"
    else
      "Exceptional Growth"
    end
  end

  def weight_progress_percentage
    return 0 unless prev_weight && current_weight && prev_weight > 0
    ((current_weight - prev_weight) / prev_weight * 100).round(1)
  end

  def expected_adult_weight
    # Holstein calves typically reach 500-600kg as adults
    return nil unless breed && current_weight

    case breed.downcase
    when "holstein"
      550 # kg
    when "jersey"
      400 # kg
    when "ayrshire"
      500 # kg
    else
      500 # kg default
    end
  end

  def growth_projection_to_adult
    return nil unless current_weight && avg_daily_gain

    target_weight = expected_adult_weight || 500
    remaining_weight = target_weight - current_weight

    if avg_daily_gain > 0
      days_to_target = remaining_weight / avg_daily_gain
      months_to_target = (days_to_target / 30.0).round(1)

      {
        target_weight: target_weight,
        remaining_weight: remaining_weight.round(1),
        days_to_target: days_to_target.round,
        months_to_target: months_to_target
      }
    else
      nil
    end
  end

  def is_adult?
    !is_calf?
  end

  def mother_tag_number
    mother&.tag_number
  end

  # Lifecycle tracking methods
  def can_be_milked?
    status == "active" && age >= 2 && !calf?
  end

  def active?
    status == "active"
  end

  def calf?
    age < 2 || mother_id.present?
  end

  def ready_for_dairy?
    calf? && age >= 1.5 && current_weight && current_weight >= 80
  end

  def graduate_to_dairy!
    if ready_for_dairy?
      update!(status: "graduated_to_dairy")
      # Could add production capacity here
      true
    else
      false
    end
  end

  def mark_as_sold!(sale_price = nil, buyer = nil, sale_date = Date.current)
    update!(status: "sold")
    # Create animal sale record only if sale_price and buyer are provided
    if sale_price && buyer && defined?(AnimalSale)
      AnimalSale.create!(
        cow: self,
        farm: farm,
        sale_date: sale_date,
        sale_price: sale_price,
        buyer: buyer,
        animal_type: calf? ? "calf" : "cow"
      )
    end
    true
  end

  def mark_as_deceased!(death_date = Date.current, cause = nil)
    update!(status: "deceased")
    # Could create death record for tracking
    true
  end

  # Advanced Animal Management Methods

  # Health Management
  def latest_health_record
    health_records.order(recorded_at: :desc).first
  end

  def current_health_status
    latest_health_record&.health_status || "unknown"
  end

  def requires_health_attention?
    latest_health = latest_health_record
    return false unless latest_health

    latest_health.requires_attention? ||
    latest_health.days_since_recorded > 30
  end

  def temperature_history(days = 30)
    health_records.with_temperature
                 .where(recorded_at: days.days.ago..Time.current)
                 .order(:recorded_at)
                 .pluck(:recorded_at, :temperature)
  end

  def weight_history(days = 90)
    health_records.with_weight
                 .where(recorded_at: days.days.ago..Time.current)
                 .order(:recorded_at)
                 .pluck(:recorded_at, :weight)
  end

  # Breeding Management
  def current_breeding_record
    breeding_records.where(breeding_status: [ "confirmed", "pending_confirmation" ]).order(:breeding_date).last
  end

  def is_pregnant?
    current_breeding_record&.breeding_status == "confirmed"
  end

  def expected_due_date
    current_breeding_record&.expected_due_date
  end

  def days_to_due_date
    current_breeding_record&.days_to_due_date
  end

  def is_due_soon?
    current_breeding_record&.is_due_soon?
  end

  def breeding_history
    breeding_records.order(:breeding_date)
  end

  def last_calving_date
    breeding_records.where(breeding_status: "completed")
                   .order(:actual_due_date)
                   .last&.actual_due_date
  end

  def days_since_last_calving
    return nil unless last_calving_date
    (Date.current - last_calving_date).to_i
  end

  # Vaccination Management
  def vaccination_status
    overdue_vaccinations_records = vaccination_records.overdue
    due_soon_vaccinations_records = vaccination_records.due_soon

    if overdue_vaccinations_records.any?
      "overdue"
    elsif due_soon_vaccinations_records.any?
      "due_soon"
    else
      "up_to_date"
    end
  end

  def overdue_vaccinations
    vaccination_records.overdue.order(:next_due_date)
  end

  def upcoming_vaccinations
    vaccination_records.due_soon.order(:next_due_date)
  end

  def last_vaccination_date
    vaccination_records.order(:vaccination_date).last&.vaccination_date
  end

  def needs_vaccination?
    vaccination_status.in?([ "overdue", "due_soon" ])
  end

  # Comprehensive Health Score
  def health_score
    score = 100

    # Deduct points for health issues
    if requires_health_attention?
      score -= 30
    elsif current_health_status.in?([ "sick", "injured" ])
      score -= 50
    elsif current_health_status == "critical"
      score -= 70
    end

    # Deduct points for overdue vaccinations
    overdue_count = overdue_vaccinations.count
    score -= (overdue_count * 10)

    # Deduct points for pregnancy complications
    if is_pregnant? && current_breeding_record&.is_overdue?
      score -= 20
    end

    # Ensure score is between 0 and 100
    [ score, 0 ].max
  end

  def health_score_category
    case health_score
    when 90..100
      "excellent"
    when 75..89
      "good"
    when 60..74
      "fair"
    when 40..59
      "poor"
    else
      "critical"
    end
  end

  def health_alert_level
    if health_score < 40
      "critical"
    elsif requires_health_attention? || needs_vaccination?
      "warning"
    else
      "normal"
    end
  end

  # Display methods
  def display_name
    "#{name} (#{tag_number})"
  end

  # Soft delete methods
  def soft_delete!
    update_column(:deleted_at, Time.current)
    decrement_active_count_if_needed if status == "active"
  end

  def restore!
    update_column(:deleted_at, nil)
    increment_active_count_if_needed if status == "active"
  end

  def deleted?
    deleted_at.present?
  end

  private

  def increment_active_count_if_needed
    if status == "active"
      farm.increment!(:active_cows_count)
    end
  end

  def update_active_count_if_status_changed
    if status_changed?
      old_status = status_was
      new_status = status

      # Decrement count if changing from active to non-active
      if old_status == "active" && new_status != "active"
        farm.decrement!(:active_cows_count)
      # Increment count if changing from non-active to active
      elsif old_status != "active" && new_status == "active"
        farm.increment!(:active_cows_count)
      end
    end
  end

  def decrement_active_count_if_needed
    if status == "active"
      farm.decrement!(:active_cows_count)
    end
  end

  public

  # Lineage / Pedigree Methods
  def all_offspring
    calves + offspring_as_sire
  end

  def lineage_tree(depth = 3)
    build_lineage_tree(self, depth)
  end

  def ancestors(generations = 3)
    result = []
    current_generation = [ self ]

    generations.times do
      next_generation = []
      current_generation.each do |cow|
        next_generation << cow.mother if cow.mother
        next_generation << cow.sire if cow.sire
      end
      result += next_generation
      break if next_generation.empty?
      current_generation = next_generation
    end

    result.compact.uniq
  end

  def descendants(generations = 3)
    result = []
    current_generation = [ self ]

    generations.times do
      next_generation = []
      current_generation.each do |cow|
        offspring = cow.all_offspring
        next_generation += offspring
      end
      result += next_generation
      break if next_generation.empty?
      current_generation = next_generation
    end

    result.compact.uniq
  end

  def pedigree_summary
    {
      cow: { id: id, name: name, tag_number: tag_number, breed: breed, birth_date: birth_date },
      mother: mother ? { id: mother.id, name: mother.name, tag_number: mother.tag_number, breed: mother.breed } : nil,
      sire: sire ? { id: sire.id, name: sire.name, tag_number: sire.tag_number, breed: sire.breed } : nil,
      maternal_grandmother: mother&.mother ? { id: mother.mother.id, name: mother.mother.name, tag_number: mother.mother.tag_number } : nil,
      maternal_grandfather: mother&.sire ? { id: mother.sire.id, name: mother.sire.name, tag_number: mother.sire.tag_number } : nil,
      paternal_grandmother: sire&.mother ? { id: sire.mother.id, name: sire.mother.name, tag_number: sire.mother.tag_number } : nil,
      paternal_grandfather: sire&.sire ? { id: sire.sire.id, name: sire.sire.name, tag_number: sire.sire.tag_number } : nil
    }
  end

  private

  def build_lineage_tree(cow, depth, current_depth = 0)
    return nil if cow.nil? || current_depth >= depth

    {
      id: cow.id,
      name: cow.name,
      tag_number: cow.tag_number,
      breed: cow.breed,
      birth_date: cow.birth_date,
      status: cow.status,
      children: cow.all_offspring.map { |child| build_lineage_tree(child, depth, current_depth + 1) }.compact,
      mother: build_parent_info(cow.mother),
      sire: build_parent_info(cow.sire)
    }
  end

  def build_parent_info(parent)
    return nil unless parent

    {
      id: parent.id,
      name: parent.name,
      tag_number: parent.tag_number,
      breed: parent.breed,
      birth_date: parent.birth_date,
      status: parent.status
    }
  end
end
