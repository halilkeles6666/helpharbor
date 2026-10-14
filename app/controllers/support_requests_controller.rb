# Public-facing support request form. No authentication: this is how a
# customer opens a ticket, the entry point of the aort dilimi.
class SupportRequestsController < ApplicationController
  allow_unauthenticated_access only: %i[new create thanks]

  def new
    @ticket = Ticket.new(priority: "normal")
  end

  def create
    @ticket = Ticket.new(support_params)
    @ticket.status = "new"

    if @ticket.save
      redirect_to support_thanks_path(@ticket.reference)
    else
      flash.now[:alert] = "Lütfen işaretli alanları düzeltin."
      render :new, status: :unprocessable_entity
    end
  end

  def thanks
    @ticket = Ticket.find_by!(reference: params[:reference])
  end

  private

  def support_params
    params.require(:ticket).permit(
      :subject, :description, :priority, :requester_name, :requester_email
    )
  end
end
