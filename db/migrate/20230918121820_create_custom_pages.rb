class CreateCustomPages < ActiveRecord::Migration[7.0]
  def change
    create_table :custom_pages do |t|
      t.string :title
      t.string :slug
      t.text :template
      t.json :metadata

      t.timestamps
    end
  end
end
