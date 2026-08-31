# frozen_string_literal: true

class EpisodeContentDescriptor < ApplicationRecord
  belongs_to :episode
  belongs_to :content_descriptor
end
