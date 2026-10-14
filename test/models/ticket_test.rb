require "test_helper"

class TicketTest < ActiveSupport::TestCase
  def build_ticket(priority: "normal", **attrs)
    Ticket.create!(subject: "Help", requester_email: "req@example.com", priority: priority, **attrs)
  end

  # ---- creation / references / SLA assignment ----

  test "creation assigns a unique HH reference and the matching SLA policy" do
    ticket = build_ticket(priority: "high")
    assert_match(/\AHH-\d{6}\z/, ticket.reference)
    assert_equal sla_policies(:high), ticket.sla_policy
    assert_equal "new", ticket.status
  end

  test "requires subject and a valid email" do
    assert_not Ticket.new(requester_email: "x@y.com").valid?
    assert_not Ticket.new(subject: "x", requester_email: "not-an-email").valid?
  end

  # ---- TIME RULE: SLA is scheduled in business hours (travel_to) ----

  test "SLA due dates are computed in business hours and skip the weekend" do
    travel_to Time.zone.local(2026, 10, 16, 16, 30) do # Friday 16:30
      ticket = build_ticket(priority: "normal") # first response 120 business min
      # 30 min Friday + 90 min Monday 09:00..10:30
      assert_equal Time.zone.local(2026, 10, 19, 10, 30), ticket.first_response_due_at
      assert_equal BusinessHours.advance(Time.current, 960), ticket.resolution_due_at
      assert ticket.first_response_due_at.on_weekday?
    end
  end

  test "no active SLA policy leaves due dates blank" do
    sla_policies(:low).update!(active: false)
    ticket = build_ticket(priority: "low")
    assert_nil ticket.sla_policy
    assert_nil ticket.first_response_due_at
    assert_nil ticket.resolution_due_at
  end

  # ---- STATUS MACHINE ----

  test "allowed transitions follow the state machine" do
    ticket = build_ticket
    assert ticket.can_transition_to?("open")
    assert ticket.can_transition_to?("solved")
    assert_not ticket.can_transition_to?("pending") # cannot go new -> pending
  end

  test "transition_to! advances status and rejects illegal moves" do
    ticket = build_ticket
    assert ticket.transition_to!("open")
    assert_equal "open", ticket.reload.status

    assert_not ticket.transition_to!("closed") # open -> closed is illegal
    assert_equal "open", ticket.reload.status
    assert ticket.errors[:status].any?
  end

  test "solving stamps solved_at and closing stamps closed_at" do
    ticket = build_ticket
    travel_to Time.zone.local(2026, 10, 12, 10, 0) do
      ticket.transition_to!("solved")
      assert_equal Time.current, ticket.solved_at
    end
    travel_to Time.zone.local(2026, 10, 12, 11, 0) do
      ticket.transition_to!("closed")
      assert_equal Time.current, ticket.closed_at
    end
  end

  test "reopening a solved ticket clears solved_at" do
    ticket = build_ticket
    ticket.transition_to!("solved")
    assert ticket.transition_to!("open")
    assert_nil ticket.reload.solved_at
  end

  # ---- TIME RULE: pending pauses the resolution clock (travel_to) ----

  test "time spent pending pushes the resolution due date forward" do
    travel_to Time.zone.local(2026, 10, 12, 9, 0) do # Monday 09:00
      @ticket = build_ticket(priority: "normal") # resolution 960 min -> Tue 17:00
      @original_due = @ticket.resolution_due_at
      @ticket.transition_to!("open")
    end
    assert_equal Time.zone.local(2026, 10, 13, 17, 0), @original_due

    travel_to(Time.zone.local(2026, 10, 12, 10, 0)) { @ticket.transition_to!("pending") }
    assert_equal Time.zone.local(2026, 10, 12, 10, 0), @ticket.pending_since

    travel_to(Time.zone.local(2026, 10, 12, 15, 0)) { @ticket.transition_to!("open") } # 300 business min paused

    assert_nil @ticket.pending_since
    # Tue 17:00 + 300 business min -> Wed 14:00
    assert_equal Time.zone.local(2026, 10, 14, 14, 0), @ticket.resolution_due_at
  end

  # ---- breach logic ----

  test "first response breach when no reply arrives before the target" do
    travel_to Time.zone.local(2026, 10, 12, 9, 0) do
      @ticket = build_ticket(priority: "normal") # first response due Mon 11:00
    end
    travel_to Time.zone.local(2026, 10, 12, 12, 0) do
      assert @ticket.first_response_breached?
    end
  end

  test "resolution breach when past due with no pending pause" do
    travel_to Time.zone.local(2026, 10, 12, 9, 0) do
      @ticket = build_ticket(priority: "normal") # resolution due Tue 17:00
    end
    travel_to Time.zone.local(2026, 10, 14, 9, 0) do # Wednesday, past due
      assert @ticket.resolution_breached?
    end
  end

  test "resolution is not breached while paused in pending, even long after the due date" do
    travel_to(Time.zone.local(2026, 10, 12, 9, 0)) { @ticket = build_ticket(priority: "normal") }
    travel_to Time.zone.local(2026, 10, 12, 9, 30) do
      @ticket.transition_to!("open")
      @ticket.transition_to!("pending")
    end
    travel_to Time.zone.local(2026, 10, 16, 12, 0) do # Friday, far past the original due
      assert_not @ticket.resolution_breached?, "clock should be frozen while pending"
    end
  end
end
