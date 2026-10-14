require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 10, 12, 9, 0) do
      @ticket = Ticket.create!(subject: "Help", requester_email: "req@example.com", priority: "normal")
    end
    @agent = users(:agent)
  end

  test "first public agent reply records first_responded_at once" do
    travel_to Time.zone.local(2026, 10, 12, 10, 0) do
      @ticket.comments.create!(author: @agent, via: "agent", body: "On it!")
      assert_equal Time.current, @ticket.reload.first_responded_at
    end

    travel_to Time.zone.local(2026, 10, 12, 11, 0) do
      @ticket.comments.create!(author: @agent, via: "agent", body: "Update")
      assert_equal Time.zone.local(2026, 10, 12, 10, 0), @ticket.reload.first_responded_at
    end
  end

  test "internal note does not record a first response" do
    @ticket.comments.create!(author: @agent, via: "agent", body: "private", internal: true)
    assert_nil @ticket.reload.first_responded_at
  end

  test "requester message does not record a first response" do
    @ticket.comments.create!(via: "requester", body: "any news?")
    assert_nil @ticket.reload.first_responded_at
  end

  test "requires a body" do
    assert_not @ticket.comments.new(via: "agent").valid?
  end
end
