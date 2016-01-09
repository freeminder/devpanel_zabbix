class CreateHostgroups < ActiveRecord::Migration
  def change
    create_table :hostgroups do |t|

      t.timestamps null: false
    end
    add_column :hostgroups, :name, :string
    add_reference :hosts, :hostgroup, index: true
  end
end
