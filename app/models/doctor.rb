class Doctor < ApplicationRecord
  belongs_to :person
  has_many :appointments
  enum :status, {
    active: 'active', on_leave: 'on_leave', retired: 'retired'
  }, default: 'active', prefix: true
  validates :person, uniqueness: true
  validates :npi, presence: true, length: { is: 10 }, format: { with: /\A[0-9]+\z/, message: 'only allows numbers' },
                  uniqueness: true
  validate :check_status
  def check_status
    errors.add(:status, 'You must choose a valid status') unless %w[active on_leave
  end
end
