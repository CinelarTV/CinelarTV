# frozen_string_literal: true

module CinelarTV
  class Application < Rails::Application
    unless defined? ::CinelarTV::Application::Version
      module Version
        MAJOR = 0
        MINOR = 1
        TINY = 0
        PRE = "beta2"

        FULL = [MAJOR, MINOR, TINY, PRE].compact.join(".")
      end
    end
  end
end
