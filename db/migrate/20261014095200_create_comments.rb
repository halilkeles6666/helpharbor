class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :author, null: true, foreign_key: { to_table: :users }
      t.text    :body, null: false
      t.boolean :internal, null: false, default: false
      t.string  :via, null: false, default: "agent"

      t.timestamps
    end
  end
end
