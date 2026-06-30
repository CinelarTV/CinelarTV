# frozen_string_literal: true

# name: styleguide
# about: Preview how UI Components are Styled in CinelarTV
# version: 0.1
# authors: CinelarTV

register_asset "styles/styleguide.css"

enabled_site_setting :styleguide_enabled

module ::Styleguide
  PLUGIN_NAME = "styleguide"
end
