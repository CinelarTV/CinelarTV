# frozen_string_literal: true

class CastMember < ApplicationRecord
  belongs_to :content
  belongs_to :person

  validates :content_id, uniqueness: { scope: :person_id }

  scope :ordered, -> { order(:order) }

  def as_json(options = {})
    data = super(options.merge(only: %i[id character_name order]))
    data[:person] = person.as_json if person
    data
  end
end
