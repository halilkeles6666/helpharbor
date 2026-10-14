require "test_helper"

# End-to-end test of the aort dilimi (core workflow):
#   customer submits a ticket (public) -> agent signs in -> sees it in the
#   queue -> replies (first-response SLA clock stops) -> drives it through the
#   status machine to solved.
class AortaSliceTest < ActionDispatch::IntegrationTest
  def sign_in_as(user, password = "password")
    post session_path, params: { email_address: user.email_address, password: password }
  end

  test "a support request travels end to end from new to solved" do
    # 1) Customer opens a ticket from the public form (no login).
    assert_difference -> { Ticket.count }, 1 do
      post support_requests_path, params: {
        ticket: {
          subject: "Checkout page throws a 500 error",
          description: "Every time I pay, I get an error screen.",
          priority: "high",
          requester_name: "Deniz K.",
          requester_email: "deniz@example.com"
        }
      }
    end
    ticket = Ticket.order(:created_at).last
    assert_equal "new", ticket.status
    assert ticket.first_response_due_at.present?, "SLA should be scheduled on creation"
    assert_redirected_to support_thanks_path(ticket.reference)
    follow_redirect!
    assert_response :success
    assert_select ".big-ref", text: ticket.reference

    # Agent area must be gated behind authentication.
    get ticket_path(ticket)
    assert_redirected_to new_session_path

    # 2) Agent signs in.
    sign_in_as users(:agent)
    follow_redirect!
    assert_response :success

    # 3) Ticket shows up in the queue and on its own page.
    get tickets_path
    assert_response :success
    assert_select "a.ref", text: ticket.reference

    get ticket_path(ticket)
    assert_response :success
    assert_select "h1", text: ticket.subject

    # 4) Agent posts a public reply -> first-response clock stops.
    assert_nil ticket.reload.first_responded_at
    post ticket_comments_path(ticket), params: { comment: { body: "Hi Deniz, investigating now." } }
    assert_redirected_to ticket_path(ticket)
    assert ticket.reload.first_responded_at.present?, "public agent reply should stamp first_responded_at"

    # 5) Drive the status machine: new -> open -> pending -> open -> solved.
    patch status_ticket_path(ticket), params: { status: "open" }
    assert_equal "open", ticket.reload.status

    patch status_ticket_path(ticket), params: { status: "pending" }
    assert_equal "pending", ticket.reload.status
    assert ticket.pending_since.present?

    patch status_ticket_path(ticket), params: { status: "open" }
    assert_nil ticket.reload.pending_since, "leaving pending clears the pause marker"

    patch status_ticket_path(ticket), params: { status: "solved" }
    assert_equal "solved", ticket.reload.status
    assert ticket.solved_at.present?
  end

  test "an illegal status transition is rejected and reported" do
    sign_in_as users(:agent)
    ticket = Ticket.create!(subject: "x", requester_email: "z@z.com", priority: "normal")

    patch status_ticket_path(ticket), params: { status: "closed" } # new -> closed is illegal
    assert_redirected_to ticket_path(ticket)
    assert_equal "new", ticket.reload.status
  end

  test "agent can assign a ticket to themselves" do
    agent = users(:agent)
    sign_in_as agent
    ticket = Ticket.create!(subject: "x", requester_email: "z@z.com", priority: "normal")

    patch assign_ticket_path(ticket), params: { assignee_id: agent.id }
    assert_equal agent, ticket.reload.assignee
  end
end
