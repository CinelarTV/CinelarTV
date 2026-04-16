class CreateBackups < ActiveRecord::Migration[7.0]
  def change
    create_table :backups do |t|
      t.string :filename, null: false
      t.bigint :size
      t.string :backup_type
      t.string :source
      t.text :notes
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    add_index :backups, :filename, unique: true
  end
end
