# HelpHarbor seed data — idempotent, safe to run repeatedly.
# Business minutes below are *working* minutes: with a 09:00–17:00 Mon–Fri
# schedule, one business day = 480 minutes.

sla = {
  "urgent" => { name: "Urgent",   first_response_minutes: 30,  resolution_minutes: 240 },   # 30 min / 4 h
  "high"   => { name: "High",     first_response_minutes: 60,  resolution_minutes: 480 },   # 1 h / 1 day
  "normal" => { name: "Normal",   first_response_minutes: 120, resolution_minutes: 960 },   # 2 h / 2 days
  "low"    => { name: "Low",      first_response_minutes: 240, resolution_minutes: 1920 }   # 4 h / 4 days
}

sla.each do |priority, attrs|
  policy = SlaPolicy.find_or_initialize_by(priority: priority)
  policy.update!(attrs.merge(active: true))
end

agent = User.find_or_initialize_by(email_address: "agent@helpharbor.test")
agent.update!(name: "Demo Agent", role: "agent", password: "password", password_confirmation: "password")

admin = User.find_or_initialize_by(email_address: "admin@helpharbor.test")
admin.update!(name: "Demo Admin", role: "admin", password: "password", password_confirmation: "password")

if Ticket.count.zero?
  t1 = Ticket.create!(
    subject: "Cannot reset my password",
    description: "The reset email never arrives even after several tries.",
    priority: "high",
    requester_name: "Ayşe Yılmaz",
    requester_email: "ayse@example.com",
    assignee: agent
  )
  t1.comments.create!(author: agent, via: "agent", body: "Hi Ayşe — looking into this now, thanks for your patience.")

  Ticket.create!(
    subject: "Billing charged twice this month",
    description: "I see two identical charges on my card for the same invoice.",
    priority: "urgent",
    requester_name: "John Carter",
    requester_email: "john@example.com"
  )

  Ticket.create!(
    subject: "Feature request: dark mode",
    description: "Would love a dark theme for the agent dashboard.",
    priority: "low",
    requester_name: "Priya S.",
    requester_email: "priya@example.com"
  )
end

puts "Seeded: #{SlaPolicy.count} SLA policies, #{User.count} users, #{Ticket.count} tickets."
