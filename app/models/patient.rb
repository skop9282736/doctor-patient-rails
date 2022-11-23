class Patient < ApplicationRecord
  belongs_to :person
  belongs_to :doctor
  validates :upi, presence: true, length: { is: 18 },
                  format: { with: /\A[A-Za-z0-9]+\z/, message: 'only allows Alphanumeric' },
                  uniqueness: true
  validate :check_if_dr_and_pr_are_diff

  def check_if_dr_and_pr_are_diff
    return unless doctor

    errors.add(:base, 'doctor and patient are the same person') if person == doctor.person
  end
end
