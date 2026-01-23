class User < ApplicationRecord
  has_secure_password
  
  belongs_to :farm
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: %w[farm_owner farm_manager farm_worker veterinarian] }
  
  scope :active, -> { where(active: true) }
  scope :by_role, ->(role) { where(role: role) }
  
  # Remove enum definition since we're using string values directly
  validates :role, inclusion: { in: %w[farm_worker farm_manager farm_owner veterinarian] }
  
  def farm_worker?
    role == 'farm_worker'
  end
  
  def farm_manager?
    role == 'farm_manager'
  end
  
  def farm_owner?
    role == 'farm_owner'
  end
  
  def veterinarian?
    role == 'veterinarian'
  end
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def can_manage_farm?
    farm_owner? || farm_manager?
  end
  
  def can_view_reports?
    farm_owner? || farm_manager? || veterinarian?
  end
  
  def can_add_production_records?
    true # All users can add production records
  end
  
  def update_last_sign_in!
    update(last_sign_in_at: Time.current)
  end
  
  def accessible_farms
    # For now, users can only access their own farm
    # In future, this could be expanded for multi-farm access
    [farm].compact
  end
end
