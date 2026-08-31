# frozen_string_literal: true

class ContentContentDescriptor < ApplicationRecord
  belongs_to :content
  belongs_to :content_descriptor
end
