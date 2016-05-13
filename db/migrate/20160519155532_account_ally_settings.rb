class AccountAllySettings < ActiveRecord::Migration
  tag :predeploy

  def up
    add_column :accounts, :ally_client_id, :string
    add_column :accounts, :ally_crypted_secret, :string
    add_column :accounts, :ally_salt, :string
    add_column :accounts, :ally_base_url, :string
  end

  def down
    remove_column :accounts, :ally_client_id
    remove_column :accounts, :ally_crypted_secret
    remove_column :accounts, :ally_salt
    remove_column :accounts, :ally_base_url
  end
end
