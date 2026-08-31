# frozen_string_literal: true

class AddContentRatingToContentsAndEpisodes < ActiveRecord::Migration[7.2]
  def change
    # FK en contents
    add_reference :contents, :content_rating, type: :uuid, null: true, foreign_key: true
    add_column :contents, :content_rating_code, :string

    # FK en episodes
    add_reference :episodes, :content_rating, type: :uuid, null: true, foreign_key: true
    add_column :episodes, :content_rating_code, :string

    # Tabla join content <-> content_descriptors
    create_table :content_content_descriptors, id: :uuid do |t|
      t.references :content, type: :uuid, null: false, foreign_key: true
      t.references :content_descriptor, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
    add_index :content_content_descriptors, %i[content_id content_descriptor_id], unique: true,
              name: "idx_ccd_on_content_and_descriptor"

    # Tabla join episode <-> content_descriptors
    create_table :episode_content_descriptors, id: :uuid do |t|
      t.references :episode, type: :uuid, null: false, foreign_key: true
      t.references :content_descriptor, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
    add_index :episode_content_descriptors, %i[episode_id content_descriptor_id], unique: true,
              name: "idx_ecd_on_episode_and_descriptor"
  end
end
