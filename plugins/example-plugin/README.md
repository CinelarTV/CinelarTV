# Example Plugin

Este es un plugin de ejemplo para demostrar el sistema de plugins de CinelarTV inspirado en Discourse.

## Características Demostradas

- **Metadata del plugin**: Definición de nombre, versión, autores, etc.
- **Enable/Disable**: Uso de SiteSetting para habilitar/deshabilitar el plugin
- **Extensión de modelos**: Agregar métodos a modelos existentes (`add_to_class`)
- **Callbacks de modelos**: Agregar callbacks condicionales (`add_model_callback`)
- **Registro central**: Uso de PluginRegistry para registrar datos
- **Sistema de eventos**: Suscripción a eventos del core (`on`)
- **Assets**: Registro de CSS y JavaScript
- **Dashboard widgets**: Widgets para el dashboard de admin
- **Menú items**: Items personalizados para el menú de admin
- **Seed data**: Datos iniciales para el plugin

## Estructura de Archivos

```
example-plugin/
  plugin.rb                    # Punto de entrada del plugin
  assets/
    javascripts/
      example-plugin.js       # JavaScript del plugin
    stylesheets/
      example-plugin.css      # CSS del plugin
  config/
    site_settings.yml         # Configuración del plugin
  README.md                   # Este archivo
```

## Configuración

El plugin se puede habilitar/deshabilitar mediante el SiteSetting `example_plugin_enabled`.

## Uso

Una vez activado, el plugin:

1. Agrega el método `example_plugin_data` a todos los usuarios
2. Registra un callback que se ejecuta al crear usuarios
3. Registra campos personalizados para usuarios
4. Agrega un widget al dashboard de admin
5. Agrega un item al menú de admin
6. Escucha eventos de usuario creados y logins

## Eventos

El plugin escucha los siguientes eventos:

- `:user_created` - Se dispara cuando se crea un nuevo usuario
- `:user_login` - Se dispara cuando un usuario inicia sesión

## Extensión

Este plugin sirve como base para crear plugins más complejos. Puedes:

- Agregar más métodos a modelos existentes
- Crear tus propios modelos y controladores
- Definir rutas personalizadas usando Rails::Engine
- Agregar más eventos y callbacks
- Crear interfaces de usuario complejas

## Rails::Engine (Opcional)

Para plugins más complejos que necesitan sus propias rutas, puedes crear un Engine:

```ruby
# lib/example_plugin/engine.rb
module ExamplePlugin
  class Engine < ::Rails::Engine
    engine_name "example-plugin"
    isolate_namespace ExamplePlugin
    config.autoload_paths << File.join(config.root, "lib")
  end
end

# En plugin.rb:
require_relative "lib/example_plugin/engine"
```
