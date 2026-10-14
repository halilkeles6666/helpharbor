class CreateSlaPolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :sla_policies do |t|
      t.string  :name, null: false
      t.string  :priority, null: false
      t.integer :first_response_minutes, null: false
      t.integer :resolution_minutes, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :sla_policies, :priority, unique: true
  end
end
