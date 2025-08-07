# frozen_string_literal: true

require 'active_support/concern'

module Videoable
  extend ActiveSupport::Concern

  included do
    has_many :video_sources, as: :videoable, dependent: :destroy
  end
end
