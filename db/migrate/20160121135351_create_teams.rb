class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name, default: true
      t.timestamps null: false
    end
    add_reference :users, :team, index: true
  end
end
