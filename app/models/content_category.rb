# frozen_string_literal: true

class ContentCategory < ApplicationRecord
  belongs_to :content
  belongs_to :category
end
