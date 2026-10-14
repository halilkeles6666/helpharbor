class Comment < ApplicationRecord
  VIA = %w[agent requester].freeze

  belongs_to :ticket
  belongs_to :author, class_name: "User", optional: true

  validates :body, presence: true
  validates :via, inclusion: { in: VIA }

  after_create :mark_first_response

  scope :public_replies, -> { where(internal: false) }
  scope :chronological, -> { order(created_at: :asc) }

  def internal_note?
    internal?
  end

  private

  # The first public agent reply stops the first-response SLA clock.
  def mark_first_response
    return if internal?
    return unless via == "agent"
    ticket.record_first_response!
  end
end
