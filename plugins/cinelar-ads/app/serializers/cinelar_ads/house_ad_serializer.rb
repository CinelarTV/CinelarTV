# frozen_string_literal: true

module CinelarAds
  class HouseAdSerializer < ActiveModel::Serializer
    attributes :id, :name, :html, :visible_to_anons, :visible_to_logged_in_users,
               :categories, :content_types, :created_at, :updated_at

    def categories
      object.categories.map { |c| { id: c.id, name: c.name } }
    end

    def content_types
      object.house_ad_content_types.pluck(:content_type)
    end
  end
end
