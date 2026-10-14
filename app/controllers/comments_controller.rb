# Agent replies and internal notes on a ticket. A public reply (internal=false)
# stops the first-response SLA clock via Comment#mark_first_response.
class CommentsController < ApplicationController
  def create
    @ticket  = Ticket.find(params[:ticket_id])
    @comment = @ticket.comments.new(comment_params)
    @comment.author = current_user
    @comment.via = "agent"

    if @comment.save
      redirect_to @ticket, notice: @comment.internal? ? "İç not eklendi." : "Yanıt gönderildi."
    else
      redirect_to @ticket, alert: @comment.errors.full_messages.to_sentence
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :internal)
  end
end
