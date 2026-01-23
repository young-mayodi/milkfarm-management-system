class Cow < ApplicationRecord
  # Associations
  belongs_to :farm
  belongs_to :mother, class_name: 'Cow', optional: true
  has_many :calves, class_name: 'Cow', foreign_key: 'mother_id', dependent: :nullify
  has_many :production_records, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :tag_number, presence: true, uniqueness: { scope: :farm_id }
  validates :breed, presence: true
  validates :age, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[active inactive pregnant sick] }
  
  # Validations for weight and growth data
  validates :current_weight, numericality: { greater_than: 0 }, allow_nil: true
  validates :prev_weight, numericality: { greater_than: 0 }, allow_nil: true
  validates :weight_gain, numericality: true, allow_nil: true
  validates :avg_daily_gain, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_group, ->(group) { where(group_name: group) }
  scope :adult_cows, -> { where('cows.age >= ? AND cows.mother_id IS NULL', 2) }
  scope :calves, -> { where('cows.age < ? OR cows.mother_id IS NOT NULL', 2) }
  scope :with_mother, -> { where.not('cows.mother_id' => nil) }

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
    when 'active' then 'success'
    when 'pregnant' then 'info'
    when 'sick' then 'danger'
    when 'inactive' then 'secondary'
    else 'light'
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
    return 'N/A' unless avg_daily_gain
    
    case avg_daily_gain
    when 0..0.4
      'Slow Growth'
    when 0.4..0.7
      'Normal Growth'  
    when 0.7..1.0
      'Fast Growth'
    else
      'Exceptional Growth'
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
    when 'holstein'
      550 # kg
    when 'jersey'
      400 # kg
    when 'ayrshire'
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
end
