# frozen_string_literal: true

require 'active_support/concern'

module Segmenteable
  extend ActiveSupport::Concern

  included do
    has_many :segments, as: :segmentable, dependent: :destroy
  end
end
