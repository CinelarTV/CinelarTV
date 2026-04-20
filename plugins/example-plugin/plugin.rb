# frozen_string_literal: true

# name: example-plugin
# version: 1.0.0
# authors: CinelarTV Team
# url: https://github.com/cinelartv/example-plugin
# required_version: 1.0.0

enabled_site_setting :example_plugin_enabled

after_initialize do
  # Agregar método a un modelo existente
  add_to_class(:user, :example_plugin_data) do
    "Example plugin data for user #{self.email}"
  end

  # Agregar callback a un modelo
  add_model_callback(:user, :after_create) do
    Rails.logger.info("[ExamplePlugin] New user created: #{self.email}")
  end

  # Registrar datos en el registry específicos de CinelarTV
  PluginRegistry.register_user_profile_field({
    name: "example_plugin_field",
    type: "string",
    label: "Example Plugin Field",
    description: "Custom field added by example plugin"
  }, self)
  
  PluginRegistry.register_content_scope({
    name: "example_plugin_scope",
    label: "Example Plugin Content",
    description: "Content scope for example plugin"
  }, self)

  # Registrar assets
  register_css("assets/stylesheets/example-plugin.css")
  register_js("assets/javascripts/example-plugin.js")

  # Suscribirse a eventos del core
  on(:user_created) do |user|
    Rails.logger.info("[ExamplePlugin] User created event received: #{user.email}")
  end

  on(:user_login) do |user|
    Rails.logger.info("[ExamplePlugin] User login event received: #{user.email}")
  end

  # Registrar dashboard widget
  PluginRegistry.register_dashboard_widget({
    name: "example_plugin_stats",
    title: "Example Plugin Stats",
    template: "example_plugin/dashboard_widget",
    position: 1
  }, self)

  # Registrar menú item para admin
  PluginRegistry.register_admin_menu_item({
    label: "Example Plugin",
    path: "/admin/example-plugin",
    icon: "fas fa-plug",
    position: 100
  }, self)

  # Registrar seed data
  PluginRegistry.register_seed_data({
    example_plugin: {
      setting1: "default_value1",
      setting2: "default_value2"
    }
  })
end
