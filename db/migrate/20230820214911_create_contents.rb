class CreateContents < ActiveRecord::Migration[7.0]
  def change
    create_table :contents do |t|
      t.string :title
      t.string :description
      t.string :banner
      t.string :cover
      t.string :type
      t.string :url
      t.integer :year

      t.timestamps
    end
  end
end
