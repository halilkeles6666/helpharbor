class Ticket < ApplicationRecord
  STATUSES   = %w[new open pending solved closed].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  # The aort dilimi (core workflow) status machine. A ticket may only move
  # along these edges; anything else is rejected by #transition_to!.
  #   new ─▶ open ─▶ pending ─▶ open ─▶ solved ─▶ closed
  #                              └────────────────▶ (reopen) open
  TRANSITIONS = {
    "new"     => %w[open solved],
    "open"    => %w[pending solved],
    "pending" => %w[open solved],
    "solved"  => %w[open closed],
    "closed"  => %w[]
  }.freeze

  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :sla_policy, optional: true
  has_many :comments, dependent: :destroy

  validates :subject, presence: true
  validates :requester_email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }

  before_validation :assign_reference, on: :create
  before_validation :assign_sla_policy, on: :create
  before_create :schedule_sla

  scope :unresolved, -> { where.not(status: %w[solved closed]) }
  scope :by_status, ->(s) { where(status: s) if s.present? }
  scope :newest_first, -> { order(created_at: :desc) }

  # ---- Status transitions -------------------------------------------------

  def available_transitions
    TRANSITIONS.fetch(status, [])
  end

  def can_transition_to?(new_status)
    available_transitions.include?(new_status.to_s)
  end

  # Move the ticket to +new_status+, applying any time-rule side effects.
  # Returns true on success, false (with errors) on an illegal transition.
  def transition_to!(new_status)
    new_status = new_status.to_s
    unless can_transition_to?(new_status)
      errors.add(:status, "#{status} durumundan #{new_status} durumuna geçilemez")
      return false
    end
    apply_status_side_effects(new_status)
    self.status = new_status
    save!
    true
  end

  # ---- SLA (business-hours aware) ----------------------------------------

  # While a ticket waits on the requester (pending) the resolution clock is
  # paused, so "now" for breach purposes freezes at the moment it went pending.
  def resolution_clock_now
    (status == "pending" && pending_since) ? pending_since : Time.current
  end

  def first_response_breached?
    return false if first_response_due_at.nil?
    (first_responded_at || Time.current) > first_response_due_at
  end

  def resolution_breached?
    return false if resolution_due_at.nil?
    (solved_at || resolution_clock_now) > resolution_due_at
  end

  # Signed business minutes left until the first-response target.
  # Positive = time remaining, negative = overdue, nil = no SLA.
  def first_response_minutes_remaining
    minutes_remaining(first_response_due_at, first_responded_at || Time.current)
  end

  def resolution_minutes_remaining
    minutes_remaining(resolution_due_at, solved_at || resolution_clock_now)
  end

  def record_first_response!
    return if first_responded_at.present?
    update_column(:first_responded_at, Time.current)
  end

  def requester_label
    requester_name.presence || requester_email
  end

  private

  def minutes_remaining(due_at, reference)
    return nil if due_at.nil?
    if reference <= due_at
      BusinessHours.minutes_between(reference, due_at)
    else
      -BusinessHours.minutes_between(due_at, reference)
    end
  end

  def apply_status_side_effects(new_status)
    # Leaving pending: resume the resolution clock by pushing the due date
    # forward by the business time spent waiting on the requester.
    if status == "pending" && new_status != "pending" && pending_since
      paused = BusinessHours.minutes_between(pending_since, Time.current)
      self.resolution_due_at = BusinessHours.advance(resolution_due_at, paused) if resolution_due_at
      self.pending_since = nil
    end

    case new_status
    when "pending"
      self.pending_since = Time.current
    when "solved"
      self.solved_at = Time.current
    when "closed"
      self.closed_at = Time.current
    when "open"
      self.solved_at = nil if status == "solved"
    end
  end

  def assign_reference
    return if reference.present?
    loop do
      candidate = "HH-#{SecureRandom.random_number(900_000) + 100_000}"
      break self.reference = candidate unless Ticket.exists?(reference: candidate)
    end
  end

  def assign_sla_policy
    self.sla_policy ||= SlaPolicy.for_priority(priority)
  end

  def schedule_sla
    return unless sla_policy
    base = Time.current
    self.first_response_due_at = BusinessHours.advance(base, sla_policy.first_response_minutes)
    self.resolution_due_at     = BusinessHours.advance(base, sla_policy.resolution_minutes)
  end
end
