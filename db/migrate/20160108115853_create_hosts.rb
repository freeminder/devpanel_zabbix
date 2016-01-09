class CreateHosts < ActiveRecord::Migration
  def change
    create_table :hosts do |t|

      t.timestamps null: false
    end
    add_column :hosts, :name, :string
    add_column :hosts, :ip, :string
    add_column :hosts, :dns, :string
    add_column :hosts, :port, :integer
    add_column :hosts, :useip, :boolean
    add_column :hosts, :host_id, :integer
  end
end
