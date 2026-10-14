module TicketsHelper
  STATUS_LABELS = {
    "new" => "Yeni", "open" => "Açık", "pending" => "Beklemede",
    "solved" => "Çözüldü", "closed" => "Kapalı"
  }.freeze

  PRIORITY_LABELS = {
    "low" => "Düşük", "normal" => "Normal", "high" => "Yüksek", "urgent" => "Acil"
  }.freeze

  def status_label(status)
    STATUS_LABELS.fetch(status, status)
  end

  def priority_label(priority)
    PRIORITY_LABELS.fetch(priority, priority)
  end

  def status_pill(status)
    tag.span(status_label(status), class: "pill pill--#{status}")
  end

  def priority_tag(priority)
    tag.span(priority_label(priority), class: "prio prio--#{priority}")
  end

  def transition_label(from, to)
    case to
    when "open"    then from == "solved" ? "Yeniden aç" : "Aç"
    when "pending" then "Beklemeye al"
    when "solved"  then "Çözüldü olarak işaretle"
    when "closed"  then "Kapat"
    else to
    end
  end

  # Turn business minutes into a compact human string (g=gün, s=saat, d=dakika).
  # One business day = 480 working minutes (09:00–17:00).
  def humanize_business_minutes(mins)
    mins = mins.abs
    days  = mins / 480
    rem   = mins % 480
    hours = rem / 60
    minutes = rem % 60
    parts = []
    parts << "#{days}g" if days.positive?
    parts << "#{hours}s" if hours.positive?
    parts << "#{minutes}d" if minutes.positive? || parts.empty?
    parts.join(" ")
  end

  # Render an SLA badge for :first_response or :resolution.
  def sla_badge(ticket, kind)
    remaining = kind == :resolution ? ticket.resolution_minutes_remaining : ticket.first_response_minutes_remaining
    return tag.span("SLA yok", class: "sla--none") if remaining.nil?

    resolved = %w[solved closed].include?(ticket.status)

    if kind == :resolution && resolved
      return remaining >= 0 ? sla_span("Zamanında çözüldü", :ok) : sla_span("SLA aşıldı", :breached)
    end

    if kind == :first_response && ticket.first_responded_at.present?
      return remaining >= 0 ? sla_span("Zamanında yanıtlandı", :ok) : sla_span("Geç yanıtlandı", :breached)
    end

    paused = kind == :resolution && ticket.status == "pending"

    if remaining.negative?
      sla_span("#{humanize_business_minutes(remaining)} gecikti", :breached)
    elsif paused
      sla_span("#{humanize_business_minutes(remaining)} (duraklatıldı)", :paused)
    elsif remaining <= 60
      sla_span("#{humanize_business_minutes(remaining)} kaldı", :soon)
    else
      sla_span("#{humanize_business_minutes(remaining)} kaldı", :ok)
    end
  end

  private

  def sla_span(text, kind)
    tag.span(text, class: "sla sla--#{kind}")
  end
end
