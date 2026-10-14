class User < ApplicationRecord
  ROLES = %w[agent admin].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :assignee_id, dependent: :nullify
  has_many :comments, foreign_key: :author_id, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :role, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end

  def display_name
    name.presence || email_address
  end
end
