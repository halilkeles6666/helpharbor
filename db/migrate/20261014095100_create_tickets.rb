class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.string   :reference, null: false
      t.string   :subject, null: false
      t.text     :description
      t.string   :status, null: false, default: "new"
      t.string   :priority, null: false, default: "normal"
      t.string   :requester_name
      t.string   :requester_email, null: false
      t.references :assignee, null: true, foreign_key: { to_table: :users }
      t.references :sla_policy, null: true, foreign_key: true

      # SLA / time-rule bookkeeping (all in the app time zone, business-hours aware)
      t.datetime :first_response_due_at
      t.datetime :resolution_due_at
      t.datetime :first_responded_at
      t.datetime :pending_since
      t.datetime :solved_at
      t.datetime :closed_at

      t.timestamps
    end
    add_index :tickets, :reference, unique: true
    add_index :tickets, :status
  end
end
