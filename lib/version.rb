# frozen_string_literal: true

module CinelarTV
    class Application < Rails::Application
      unless defined? ::CinelarTV::Application::Version
        module Version
          MAJOR = 0
          MINOR = 0
          TINY = 0
          PRE = "alpha"
  
          FULL = [MAJOR, MINOR, TINY, PRE].compact.join(".")
        end
      end
    end
  end