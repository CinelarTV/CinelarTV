class AddAccountSuspensionAndDeactivationToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :suspended, :boolean, default: false, null: false
    add_column :users, :suspended_until, :datetime
    add_column :users, :suspended_reason, :text
    add_column :users, :suspended_by_id, :uuid

    add_column :users, :deactivated_at, :datetime
    add_column :users, :deactivated_reason, :text
    add_column :users, :deactivated_by_id, :uuid

    add_index :users, :suspended_until
    add_index :users, :deactivated_at
  end
end
