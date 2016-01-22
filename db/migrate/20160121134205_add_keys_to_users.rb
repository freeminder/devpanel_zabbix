class AddKeysToUsers < ActiveRecord::Migration
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    # Zabbix user id can be parsed by email
    # add_column :users, :zbx_user_id, :string
  end
end
