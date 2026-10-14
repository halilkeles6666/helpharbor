class SlaPolicy < ApplicationRecord
  has_many :tickets, dependent: :nullify

  validates :name, presence: true
  validates :priority, presence: true, uniqueness: true
  validates :first_response_minutes, :resolution_minutes,
            numericality: { only_integer: true, greater_than: 0 }

  scope :active, -> { where(active: true) }

  # The active policy that governs a given ticket priority, if any.
  def self.for_priority(priority)
    active.find_by(priority: priority)
  end
end
