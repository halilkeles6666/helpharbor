# Agent workspace for triaging and resolving tickets. Authentication is
# required (inherited from ApplicationController's before_action).
class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show assign status]

  def index
    @status = params[:status].presence
    @tickets = Ticket.by_status(@status).newest_first.includes(:assignee, :sla_policy)
    @counts  = Ticket.group(:status).count
  end

  def show
    @comments = @ticket.comments.chronological.includes(:author)
    @comment  = @ticket.comments.new
    @agents   = User.order(:name)
  end

  # Assign (or unassign) the ticket to an agent.
  def assign
    assignee_id = params[:assignee_id].presence
    @ticket.update!(assignee_id: assignee_id)
    redirect_to @ticket, notice: assignee_id ? "Talep #{@ticket.assignee.display_name} kişisine atandı." : "Atama kaldırıldı."
  end

  # Move the ticket along the status machine (new → open → pending → solved → closed).
  def status
    if @ticket.transition_to!(params[:status])
      redirect_to @ticket, notice: "Durum güncellendi: #{@ticket.status}."
    else
      redirect_to @ticket, alert: @ticket.errors.full_messages.to_sentence
    end
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
  end
end
