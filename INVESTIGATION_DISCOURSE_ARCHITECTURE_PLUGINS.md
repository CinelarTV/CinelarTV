Aquí está el análisis arquitectónico completo del sistema de plugins de Discourse.

---

# Arquitectura del Sistema de Plugins de Discourse

## 1. Descubrimiento automático de plugins

**Problema que resuelve:** Encontrar todos los plugins instalados sin configuración manual.

**Implementación:** El método `Plugin::Instance.find_all` usa un glob de sistema de archivos:

```ruby
Dir["#{parent_path}/*/plugin.rb"].sort.each do |path|
  next if allowed && !allowed.include?(File.basename(File.dirname(path)))
  plugins << parse_from_source(path)
end
```

La convención es simple: cualquier subdirectorio de `plugins/` que contenga un archivo `plugin.rb` es un plugin. El glob también sigue symlinks, lo que permite montar plugins externos. El filtrado se controla con la variable de entorno `LOAD_PLUGINS` (`:all`, `:none`, o lista CSV de nombres). [1](#0-0) [2](#0-1) 

**Decisión de diseño:** Convención sobre configuración. No hay un archivo de registro central. La presencia del archivo `plugin.rb` es suficiente.

**Ventajas:** Zero-config para instalar un plugin (basta con copiar el directorio). Soporta symlinks para desarrollo.

**Desventajas:** No hay orden de carga garantizado más allá del orden alfabético. No hay declaración explícita de dependencias entre plugins.

---

## 2. Registro de plugins

**Problema que resuelve:** Mantener un inventario centralizado de todo lo que los plugins aportan al sistema.

**Implementación:** `DiscoursePluginRegistry` es una clase con variables de clase que actúa como registro global. Tiene dos tipos de registros:

**`define_register(name, type)`** — registro simple (Set, Hash, etc.):
```ruby
define_register :javascripts, Set
define_register :stylesheets, Hash
define_register :locales, ActiveSupport::HashWithIndifferentAccess
```

**`define_filtered_register(name)`** — registro con filtrado automático por plugin habilitado:
```ruby
define_filtered_register :staff_user_custom_fields
# Genera automáticamente:
# - _raw_staff_user_custom_fields  → todos los valores (incluso de plugins deshabilitados)
# - staff_user_custom_fields       → solo valores de plugins habilitados
# - register_staff_user_custom_field(value, plugin) → método de registro
```

El filtrado en tiempo de ejecución es la clave:
```ruby
define_singleton_method(register_name) do
  public_send(:"_raw_#{register_name}").filter_map { |h| h[:value] if h[:plugin].enabled? }.uniq
end
``` [3](#0-2) [4](#0-3) 

**Ventajas:** Los plugins deshabilitados no contaminan el sistema. El registro se puede resetear en tests con `reset!`.

**Desventajas:** Es un singleton global con estado mutable. En multisite, el estado es compartido entre todos los sitios.

---

## 3. Ciclo de vida de un plugin

**Problema que resuelve:** Separar el análisis de metadatos de la activación real, y garantizar que los plugins se inicialicen en el momento correcto del boot de Rails.

**Implementación:** Dos fases distintas:

**Fase 1 — Parse (antes del boot de Rails):**
```ruby
Plugin::Instance.parse_from_source(path)
# Lee el archivo, extrae metadatos del header de comentarios
# NO ejecuta el código Ruby del plugin
```

**Fase 2 — Activate (durante el boot de Rails):**
```ruby
def activate!
  instance_eval File.read(path), path  # Ejecuta plugin.rb en contexto del Plugin::Instance
  generate_automatic_assets!
  register_assets!
  register_locales!
  # Añade migration_paths, rake tasks, symlinks de public/
end
```

**Fase 3 — After Initialize (después del boot completo de Rails):**
```ruby
config.after_initialize do
  Discourse.plugins.each(&:notify_after_initialize)
  # Ejecuta todos los bloques `after_initialize { }` registrados en plugin.rb
end
``` [5](#0-4) [6](#0-5) [7](#0-6) 

**Decisión de diseño:** La separación parse/activate permite mostrar información de plugins en la UI antes de activarlos. El `after_initialize` garantiza que todos los modelos de ActiveRecord están disponibles cuando el plugin los necesita.

**Ventajas:** Tolerancia a fallos: si un plugin falla durante `activate!`, `Plugin.initialization_guard` captura el error, identifica el plugin culpable por el backtrace, y termina el proceso con un mensaje claro. [8](#0-7) 

---

## 4. Extensión del core sin modificarlo

Discourse usa cuatro estrategias complementarias:

### 4a. `add_to_class` — Añadir métodos a clases existentes

```ruby
def add_to_class(class_name, attr, &block)
  reloadable_patch do |plugin|
    klass = class_name.to_s.classify.constantize
    hidden_method_name = :"#{attr}_without_enable_check"
    klass.define_method(hidden_method_name, &block)
    klass.define_method(attr) do |*args, **kwargs|
      send(hidden_method_name, *args, **kwargs) if plugin.enabled?
    end
  end
end
```

El método real se guarda con sufijo `_without_enable_check`. El método público comprueba `plugin.enabled?` antes de delegar. [9](#0-8) 

### 4b. `add_to_serializer` — Añadir atributos a serializers

```ruby
def add_to_serializer(serializer, attr, ...)
  reloadable_patch do |plugin|
    base = "#{serializer}Serializer".constantize
    ([base] + base.descendants).each do |klass|
      klass.attributes(attr)
      klass.define_method("include_#{attr}?") { plugin.enabled? }
      klass.define_method(attr, &block)
    end
  end
end
```

Itera sobre `base.descendants` porque los serializers pueden estar ya instanciados y cacheados. [10](#0-9) 

### 4c. `register_modifier` — Pipeline de transformación de valores

```ruby
plugin.register_modifier(:should_bump_topic) { |value, post, ...| false }
# En el core:
result = DiscoursePluginRegistry.apply_modifier(:should_bump_topic, true, post, ...)
```

`apply_modifier` itera sobre todos los modificadores registrados para ese nombre, pasando el valor transformado de uno al siguiente, respetando `plugin.enabled?`. [11](#0-10) 

### 4d. `extend_list_method` — Extender listas de clases

```ruby
def extend_list_method(klass, method, new_attributes)
  # Registra en un filtered_register
  # Alias del método original como __original_method__
  # Redefine el método para unir original + plugin contributions
  klass.define_singleton_method(method) do
    send("__original_#{method}__") | DiscoursePluginRegistry.send(register_name).flatten
  end
end
``` [12](#0-11) 

---

## 5. Event Bus (`DiscourseEvent`)

**Problema que resuelve:** Comunicación desacoplada entre el core y los plugins, y entre plugins.

**Implementación:** Pub/sub minimalista con un Hash de Sets de bloques:

```ruby
class DiscourseEvent
  def self.events
    @events ||= Hash.new { |hash, key| hash[key] = Set.new }
  end

  def self.trigger(event_name, *args, continue_on_error: false, **kwargs)
    events[event_name].each { |event| event.call(*args, **kwargs) }
  end

  def self.on(event_name, &block)
    events[event_name] << block
  end
end
```

`Plugin::Instance#on` es un proxy que añade la comprobación de `enabled?`:
```ruby
def on(event_name, &block)
  DiscourseEvent.on(event_name) { |*args, **kwargs| block.call(*args, **kwargs) if enabled? }
end
``` [13](#0-12) [14](#0-13) 

**Ventajas:** Extremadamente simple. No requiere dependencias externas. Los bloques son objetos de primera clase en Ruby, por lo que `off` puede eliminar un listener específico.

**Desventajas:** No hay tipado de eventos. No hay garantía de orden de ejecución entre listeners. No hay soporte para eventos asíncronos. Los eventos se disparan en el mismo hilo.

---

## 6. Plugin Outlets (frontend)

**Problema que resuelve:** Permitir que plugins inserten contenido en puntos específicos de las plantillas Ember sin modificarlas.

**Implementación:** `PluginOutlet` es un componente Glimmer que actúa como punto de extensión declarado en las plantillas del core:

```handlebars
<PluginOutlet @name="above-footer" />
```

Hay dos tipos:
- **Standard outlet**: slot vacío donde los conectores se insertan
- **Wrapper outlet**: envuelve contenido existente; crea automáticamente sub-outlets `__before` y `__after`

```handlebars
<PluginOutlet @name="discovery-list-area">
  <div>Contenido por defecto</div>
</PluginOutlet>
``` [15](#0-14) [16](#0-15) 

**Ventajas:** Los outlets soportan aliases para renombrar sin romper plugins existentes. Soportan deprecación explícita con mensajes y versiones.

---

## 7. Conectores (frontend)

**Problema que resuelve:** Mecanismo concreto para que un plugin "conecte" a un outlet.

**Implementación:** Dos mecanismos:

**Mecanismo 1 — File-based (convención de carpetas):**
```
plugins/my-plugin/assets/javascripts/discourse/connectors/evil-trout/hello.gjs
```
Cualquier archivo `.gjs` en `connectors/<outlet-name>/` se registra automáticamente como conector para ese outlet. El nombre del archivo no importa (pero debe ser único entre todos los plugins). [17](#0-16) 

**Mecanismo 2 — Programático via Plugin API:**
```javascript
api.renderInOutlet('evil-trout', MyComponent);
api.renderBeforeWrapperOutlet('discovery-list-area', BeforeComponent);
api.renderAfterWrapperOutlet('discovery-list-area', AfterComponent);
``` [18](#0-17) 

El componente `PluginConnector` envuelve cada conector y gestiona su ciclo de vida (`setupComponent`, `teardownComponent`). [19](#0-18) 

---

## 8. Monkey patches seguros (`reloadable_patch` y `freedom_patches`)

**Problema que resuelve:** Modificar clases existentes de forma que sea compatible con el hot-reload de Rails en desarrollo.

**Implementación — `reloadable_patch`:**

```ruby
def reloadable_patch(plugin = self)
  if Rails.env.development? && defined?(ActiveSupport::Reloader)
    ActiveSupport::Reloader.to_prepare do
      yield plugin  # Se re-ejecuta en cada reload
    end
  end
  yield plugin  # Se ejecuta siempre (incluyendo la primera vez)
end
```

En desarrollo, el bloque se registra en `ActiveSupport::Reloader.to_prepare`, que lo re-ejecuta cada vez que Rails recarga las clases. En producción, solo se ejecuta una vez. [20](#0-19) 

**Implementación — `freedom_patches`:**

El directorio `lib/freedom_patches/` contiene monkey patches de gems y stdlib de Ruby. Están explícitamente excluidos del autoloader de Zeitwerk:
```ruby
Rails.autoloaders.main.ignore("lib/freedom_patches")
```
Se cargan manualmente con `require`. Usan `Module#prepend` en lugar de `alias_method` para mayor seguridad:
```ruby
Propshaft::Helper.prepend(Module.new do
  def compute_asset_path(path, options = {})
    # override con super disponible
  end
end)
``` [21](#0-20) [22](#0-21) 

**Ventajas de `prepend` sobre `alias_method`:** La cadena de herencia queda limpia. `super` funciona naturalmente. No hay colisiones de nombres.

---

## 9. Carga de assets

**Problema que resuelve:** Compilar y servir el JavaScript y CSS de cada plugin de forma independiente.

**Implementación backend:** Durante `activate!`, los assets se registran en `DiscoursePluginRegistry`:
```ruby
register_assets! # → DiscoursePluginRegistry.register_asset(asset, opts, plugin_directory_name)
``` [23](#0-22) 

**Compilación JS — `Plugin::JsManager`:**

Cada plugin tiene su propio bundle compilado. El proceso:
1. Escanea `assets/javascripts/`, `admin/assets/javascripts/`, `test/javascripts/`
2. Calcula un digest SHA1 del contenido de todos los archivos
3. Si el bundle no existe o el digest cambió, lo compila con `Plugin::JsCompiler`
4. Genera un `manifest.json` con los entrypoints y sus hashes
5. En desarrollo, un watcher de archivos recompila automáticamente al detectar cambios y publica en MessageBus para forzar refresh del browser

La compilación es paralela (hasta 4 procesos):
```ruby
Parallel.each(Discourse.plugins, in_processes: parallel_count) do |plugin|
  compile_js_bundle(plugin)
end
``` [24](#0-23) 

**Decisión de diseño:** Cada plugin tiene su propio bundle con digest en el nombre del archivo (cache-busting automático). Los bundles se almacenan en `app/assets/generated/<plugin_directory_name>/`.

---

## 10. Registro de rutas

**Backend:** Los plugins usan `Rails::Engine` con `isolate_namespace`:
```ruby
# En plugin.rb:
module ::MyPlugin
  class Engine < ::Rails::Engine
    engine_name "my-plugin"
    isolate_namespace MyPlugin
  end
end

# En config/routes.rb del plugin:
MyPlugin::Engine.routes.draw do
  get "/examples" => "examples#index"
end
Discourse::Application.routes.draw do
  mount ::MyPlugin::Engine, at: "my-plugin"
end
``` [25](#0-24) 

**Frontend:** El sistema usa un árbol de rutas (`RouteNode`) que se construye antes de pasarlo al router de Ember. Cualquier módulo cuyo nombre termine en `route-map` se descubre automáticamente:

```javascript
Object.keys(requirejs.entries).forEach(function (key) {
  if (/route-map$/.test(key)) {
    let module = requirejs(key, null, null, true);
    tree.extract(module.default);
  }
});
```

Si el módulo exporta un objeto con `{ resource, map }`, las rutas se insertan dentro del recurso especificado (ej: `admin`). [26](#0-25) 

**Decisión de diseño clave:** El `RouteNode` resuelve el problema de que el router de Ember no puede extenderse. En lugar de llamar directamente a `Router.map`, los plugins contribuyen a un árbol intermedio que se aplica de una vez.

---

## 11. Migraciones

**Problema que resuelve:** Que los plugins puedan modificar el esquema de base de datos.

**Implementación:** Durante `activate!`, se añaden los paths de migración del plugin a los paths de ActiveRecord:

```ruby
migration_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths
migration_paths << File.dirname(path) + "/db/migrate"
migration_paths << "#{File.dirname(path)}/#{Discourse::DB_POST_MIGRATE_PATH}"
```

Rails descubre y ejecuta estas migraciones automáticamente con `db:migrate`. [27](#0-26) 

**Ventajas:** Usa el mecanismo estándar de Rails. No requiere infraestructura adicional.

**Desventajas:** Las migraciones de plugins se mezclan con las del core en el historial de migraciones. No hay rollback automático al desinstalar un plugin.

---

## 12. Traducciones

**Backend:** Rails carga automáticamente los YAMLs de los plugins:
```ruby
config.i18n.load_path += Dir["#{Rails.root.join("plugins/*/config/locales/*.yml")}"]
``` [28](#0-27) 

**Registro de locales personalizados:** Los plugins pueden registrar locales completos con opciones de pluralización:
```ruby
plugin.register_locale("pl_PL", fallbackLocale: "pl", plural: { ... })
``` [29](#0-28) 

El sistema de traducción usa un acelerador (`lib/freedom_patches/translate_accelerator.rb`) que cachea traducciones en LRU y carga locales bajo demanda. [30](#0-29) 

---

## 13. Modelos, Controladores y Serializers

**Modelos:** Via `Rails::Engine` con Zeitwerk. Los archivos en `app/models/` del plugin se autocargan. Para campos personalizados en modelos del core:
```ruby
plugin.register_user_custom_field_type("my_field", :string)
plugin.allow_public_user_custom_field("my_field")
```

**Controladores:** Via `Rails::Engine`. Los controladores del plugin heredan de `ApplicationController` y usan `requires_plugin PLUGIN_NAME` para verificar que el plugin está habilitado. [31](#0-30) 

**Serializers:** Via `add_to_serializer`:
```ruby
plugin.add_to_serializer(:current_user, :my_field) { object.custom_fields["my_field"] }
```
Esto añade el atributo a `CurrentUserSerializer` y todos sus descendientes, con un `include_my_field?` que comprueba `plugin.enabled?`. [10](#0-9) 

---

## 14. Componentes frontend

Los plugins pueden añadir componentes Ember de tres formas:

1. **Archivos en `assets/javascripts/discourse/components/`** — autoincluidos en el bundle del plugin
2. **Conectores** — archivos en `connectors/<outlet-name>/` que se renderizan en outlets
3. **`api.renderInOutlet(name, Component)`** — registro programático

Los componentes del plugin viven en el namespace `discourse/plugins/<plugin-name>/...` dentro del sistema de módulos de Ember.

---

## 15. Aislamiento del código de cada plugin

**Backend:**
- Namespace de módulo Ruby propio (`module ::MyPlugin`)
- `Rails::Engine` con `isolate_namespace` evita que las rutas y helpers contaminen el namespace global
- Las migraciones tienen su propio directorio

**Frontend:**
- Namespace de módulos: `discourse/plugins/<plugin-name>/...`
- Los bundles JS son archivos separados con sus propios source maps
- Los conectores se identifican por su path de módulo

**Limitación importante:** No hay sandbox real. Un plugin puede acceder a cualquier clase Ruby del core. El aislamiento es por convención, no por enforcement.

---

## 16. Dependencias entre plugins

**Problema que resuelve:** Evitar activar plugins que requieren una versión mínima de Discourse.

**Implementación:** El campo `required_version` en el header del `plugin.rb`:
```ruby
# required_version: 2.8.0
```

Durante `activate_plugins!`:
```ruby
v = p.metadata.required_version || Discourse::VERSION::STRING
if Discourse.has_needed_version?(Discourse::VERSION::STRING, v)
  p.activate!
else
  STDERR.puts "Could not activate #{p.metadata.name}..."
end
``` [7](#0-6) 

**Limitación:** No hay declaración de dependencias entre plugins (plugin A requiere plugin B). Esto se gestiona por convención y documentación, no por el sistema.

---

## 17. Gestión de versiones

**Plugin metadata:**
```ruby
# name: my-plugin
# version: 1.2.3
# required_version: 3.0.0
``` [32](#0-31) 

El campo `version` es informativo (se muestra en `/admin/plugins`). El campo `required_version` es el único que tiene efecto en el sistema de activación.

---

## 18. Habilitar/Deshabilitar plugins

**Implementación:** Cada plugin puede declarar un `SiteSetting` que controla si está habilitado:
```ruby
enabled_site_setting :my_plugin_enabled
```

El método `enabled?` consulta ese setting:
```ruby
def enabled?
  return false if !configurable?
  @enabled_site_setting ? SiteSetting.get(@enabled_site_setting) : true
end
``` [33](#0-32) 

El efecto en cascada:
- `define_filtered_register` filtra automáticamente los valores de plugins deshabilitados
- `add_to_class` envuelve los métodos con `if plugin.enabled?`
- `add_to_serializer` genera `include_attr?` que retorna `false` si el plugin está deshabilitado
- `DiscoursePluginRegistry.apply_modifier` salta los modificadores de plugins deshabilitados

**Importante:** Deshabilitar un plugin no desmonta sus rutas ni revierte sus migraciones. Es una desactivación "soft" en tiempo de ejecución.

---

## 19. Plugin API (frontend)

**Problema que resuelve:** Proveer una interfaz estable y versionada para que plugins y temas extiendan el frontend.

**Implementación:** `withPluginApi` es el punto de entrada universal:

```javascript
import { withPluginApi } from "discourse/lib/plugin-api";

withPluginApi((api) => {
  api.decorateCookedElement(...);
  api.renderInOutlet(...);
  api.registerValueTransformer(...);
});
```

`withPluginApi` obtiene (o crea) una instancia de `_PluginApi` registrada en el contenedor de Ember como `plugin-api:main`. La instancia es un singleton por `ApplicationInstance`. [34](#0-33) 

Los plugins usan `apiInitializer` para envolver su código:
```javascript
export default apiInitializer((api) => { ... });
```

Esto genera un `instanceInitializer` de Ember con `after: "inject-objects"`, garantizando que los servicios están disponibles. [35](#0-34) 

**Transformers (frontend):** Sistema análogo a los `modifiers` del backend:
- `api.registerValueTransformer(name, ({value, context}) => newValue)` — transforma un valor
- `api.registerBehaviorTransformer(name, ({next, context}) => ...)` — envuelve un comportamiento

Los nombres de transformers deben estar pre-registrados en un registry que se congela durante el boot, evitando typos silenciosos. [36](#0-35) 

---

## 20. Initializers (frontend)

**Convención de carpetas:**
```
assets/javascripts/discourse/
  pre-initializers/    → Ember initializers (una vez por app load)
  initializers/        → Ember instance-initializers (una vez por app boot)
  api-initializers/    → Igual que initializers, pero reciben la Plugin API
```

El sistema de carga escanea `requirejs.entries` buscando módulos que coincidan con los patrones:
```javascript
if (moduleName.includes("/pre-initializers/")) { ... }
else if (moduleName.includes("/initializers/") || moduleName.includes("/api-initializers/")) { ... }
``` [37](#0-36) 

---

## 21. Autoloading

Los plugins pueden usar Zeitwerk via `Rails::Engine`:
```ruby
class Engine < ::Rails::Engine
  engine_name PLUGIN_NAME
  isolate_namespace MyPlugin
  config.autoload_paths << File.join(config.root, "lib")
end
```

Esto permite que `MyPlugin::SomeClass` se cargue automáticamente desde `app/models/my_plugin/some_class.rb` sin `require` explícitos. Los cambios en desarrollo se recargan automáticamente. [38](#0-37) 

---

---

# Patrones Arquitectónicos Reutilizables de Discourse

Este documento extrae los patrones que pueden aplicarse en cualquier aplicación Rails.

---

## Patrón 1: Descubrimiento por Convención de Sistema de Archivos

**Idea:** Usar un glob para descubrir plugins automáticamente. La presencia de un archivo centinela (`plugin.rb`) en un directorio es suficiente para registrar el plugin.

```ruby
# En tu aplicación:
class PluginLoader
  def self.find_all(plugins_dir)
    Dir["#{plugins_dir}/*/plugin.rb"].sort.map do |path|
      PluginInstance.new(path)
    end
  end
end
```

**Cuándo usarlo:** Cuando quieres que instalar un plugin sea tan simple como copiar un directorio. Funciona bien con symlinks para desarrollo.

**Limitación a considerar:** Sin un archivo de manifiesto central, no puedes declarar dependencias entre plugins ni garantizar orden de carga.

---

## Patrón 2: Metadatos como Comentarios en el Archivo Principal

**Idea:** El archivo `plugin.rb` sirve como manifiesto Y como código. Los metadatos se extraen de los comentarios del header antes de ejecutar el código.

```ruby
class PluginMetadata
  FIELDS = %i[name version description authors required_version]
  attr_accessor(*FIELDS)

  def self.parse(source_text)
    meta = new
    source_text.each_line do |line|
      break unless line.strip.empty? || line.strip.start_with?("#")
      if (m = line.match(/^#\s*(\w+):\s*(.+)/))
        field = m[1].to_sym
        meta.send("#{field}=", m[2].strip) if FIELDS.include?(field)
      end
    end
    meta
  end
end
```

**Ventaja:** Un solo archivo sirve como documentación, manifiesto y código. No hay archivos YAML/JSON separados que mantener sincronizados.

---

## Patrón 3: Registry con Filtrado por Estado del Plugin

**Idea:** El registry no solo almacena valores, sino que los asocia con el plugin que los registró. Al leer, filtra automáticamente los valores de plugins deshabilitados.

```ruby
class PluginRegistry
  @@registers = Set.new

  def self.define_filtered_register(name)
    @@registers << name
    var = :"@_raw_#{name}"

    define_singleton_method("_raw_#{name}") do
      instance_variable_get(var) || instance_variable_set(var, [])
    end

    define_singleton_method(name) do
      send("_raw_#{name}").filter_map { |entry| entry[:value] if entry[:plugin].enabled? }.uniq
    end

    define_singleton_method("register_#{name.to_s.singularize}") do |value, plugin|
      send("_raw_#{name}") << { plugin: plugin, value: value }
    end
  end

  def self.reset!
    @@registers.each { |name| instance_variable_set(:"@_raw_#{name}", nil) }
  end

  define_filtered_register :email_handlers
  define_filtered_register :search_extensions
end
```

**Ventaja clave:** Habilitar/deshabilitar un plugin tiene efecto inmediato en todo el sistema sin reiniciar. El `reset!` es invaluable para tests.

---

## Patrón 4: Modifier Pipeline (Transformación en Cadena)

**Idea:** En lugar de hooks que ejecutan código arbitrario, los modifiers transforman un valor pasándolo por una cadena de funciones. Cada plugin puede modificar el valor que recibió del anterior.

```ruby
# En el registry:
def self.register_modifier(plugin, name, &block)
  @modifiers ||= {}
  @modifiers[name] ||= []
  @modifiers[name] << [plugin, block]
end

def self.apply_modifier(name, initial_value, *context_args)
  return initial_value unless @modifiers&.[](name)

  @modifiers[name].reduce(initial_value) do |value, (plugin, block)|
    plugin.enabled? ? block.call(value, *context_args) : value
  end
end

# En el core:
should_send_email = DiscoursePluginRegistry.apply_modifier(:should_send_email, true, user, notification)

# En un plugin:
plugin.register_modifier(:should_send_email) do |value, user, notification|
  value && !user.on_vacation?
end
```

**Ventaja sobre eventos:** El valor de retorno importa. Múltiples plugins pueden cooperar en una decisión. El core mantiene control del flujo.

**Diferencia con eventos:** Los eventos son "fire and forget". Los modifiers son "transform and return".

---

## Patrón 5: Monkey Patch Seguro con `reloadable_patch`

**Idea:** Envolver los monkey patches en `ActiveSupport::Reloader.to_prepare` para que sobrevivan al hot-reload de Rails en desarrollo.

```ruby
def reloadable_patch(plugin = self)
  if Rails.env.development? && defined?(ActiveSupport::Reloader)
    ActiveSupport::Reloader.to_prepare { yield plugin }
  end
  yield plugin
end

# Uso:
reloadable_patch do |plugin|
  User.define_method(:premium?) { plugin.enabled? && custom_fields["premium"] }
end
```

**Por qué funciona:** En desarrollo, Rails recarga las clases en cada request. Sin `to_prepare`, el método añadido desaparecería tras el primer reload. Con `to_prepare`, se re-aplica automáticamente.

**Usar `prepend` en lugar de `alias_method`:**
```ruby
SomeGem::SomeClass.prepend(Module.new do
  def some_method
    # tu override
    super  # llama al original limpiamente
  end
end)
```

---

## Patrón 6: Ciclo de Vida en Dos Fases (Parse + Activate)

**Idea:** Separar la lectura de metadatos de la ejecución del código del plugin. Esto permite mostrar información sobre plugins antes de activarlos, y manejar errores de activación de forma granular.

```ruby
class PluginInstance
  def self.parse_from_source(path)
    source = File.read(path)
    metadata = PluginMetadata.parse(source)
    new(metadata, path)
  end

  def activate!
    instance_eval File.read(path), path
    # registrar assets, migrations, etc.
  end

  def notify_after_initialize
    @initializers.each { |block| block.call(self) }
  end
end

# En application.rb:
plugins = PluginInstance.find_all("plugins/")
plugins.each(&:activate!)

config.after_initialize do
  plugins.each(&:notify_after_initialize)
end
```

**Ventaja:** `after_initialize` garantiza que todos los modelos de ActiveRecord están disponibles. Los plugins que necesitan acceder a la DB lo hacen en `after_initialize`, no en `activate!`.

---

## Patrón 7: Plugin Outlets en el Frontend

**Idea:** Declarar puntos de extensión explícitos en las plantillas. Los plugins "conectan" a esos puntos mediante convención de nombres de archivos o registro programático.

**Implementación conceptual en cualquier framework:**

```javascript
// En el core (plantilla):
<PluginOutlet name="user-profile-header" context={{ user }} />

// Descubrimiento de conectores (en el boot):
// Buscar todos los módulos que coincidan con el patrón
// discourse/plugins/*/connectors/<outlet-name>/*
const connectors = {};
for (const moduleName of Object.keys(moduleRegistry)) {
  const match = moduleName.match(/connectors\/([^/]+)\//);
  if (match) {
    const outletName = match[1];
    connectors[outletName] ||= [];
    connectors[outletName].push(moduleRegistry[moduleName]);
  }
}

// El componente PluginOutlet renderiza todos los conectores registrados
```

**Decisión de diseño clave:** Los outlets son declarativos en el core. Los plugins no necesitan saber nada del core para conectarse, solo conocer el nombre del outlet.

---

## Patrón 8: Extensión de Serializers sin Modificarlos

**Idea:** Añadir atributos a serializers existentes desde plugins, con la condición de que el plugin esté habilitado.

```ruby
def add_to_serializer(serializer_name, attribute, &block)
  reloadable_patch do |plugin|
    klass = "#{serializer_name}_serializer".classify.constantize

    # Incluir descendientes para cubrir subclases ya cacheadas
    ([klass] + klass.descendants).each do |serializer_class|
      serializer_class.attribute(attribute)
      serializer_class.define_method("include_#{attribute}?") { plugin.enabled? }
      serializer_class.define_method(attribute, &block)
    end
  end
end
```

**Por qué iterar sobre `descendants`:** En Rails, los serializers pueden estar ya instanciados y sus métodos cacheados. Iterar sobre descendientes garantiza que todos los subclases también reciben el atributo.

---

## Patrón 9: Rutas Frontend con Árbol Intermedio

**Problema:** Los routers de frameworks SPA (Ember, React Router) no permiten extensión post-definición.

**Solución de Discourse:** Construir un árbol de rutas antes de pasarlo al router. Los plugins contribuyen al árbol, y el árbol se aplica de una vez.

```javascript
class RouteTree {
  constructor() { this.children = {}; }

  route(name, opts, fn) {
    if (this.children[name]) {
      this.children[name].extend(fn); // merge, no replace
    } else {
      this.children[name] = new RouteNode(name, opts, fn);
    }
  }

  applyTo(router) {
    Object.values(this.children).forEach(node => node.applyTo(router));
  }
}

// Boot:
const tree = new RouteTree();
// Core define sus rutas en el árbol
// Plugins contribuyen sus rutas al árbol
// Al final, el árbol se aplica al router real
```

**Ventaja:** Los plugins pueden añadir rutas dentro de recursos existentes (ej: rutas de admin) sin modificar el archivo de rutas del core.

---

## Patrón 10: Inicializadores Frontend con Orden Explícito

**Idea:** Los initializers declaran dependencias con `before`/`after`, formando un grafo de dependencias que el framework resuelve.

```javascript
// En el core:
export default {
  name: "inject-objects",
  initialize(owner) { /* ... */ }
};

// En un plugin:
export default apiInitializer((api) => {
  // after: "inject-objects" está implícito en apiInitializer
  api.decorateCookedElement(...);
});
```

**Patrón reutilizable:** Cualquier sistema de plugins frontend debería tener un mecanismo de ordenación de inicializadores. El patrón `{ name, before, after, initialize }` de Ember es simple y efectivo.

---

## Patrón 11: Habilitación/Deshabilitación en Runtime

**Idea:** Los plugins no se "desinstalan" para deshabilitarlos. Se deshabilitan en runtime consultando un setting. Todo el código que depende del plugin comprueba `plugin.enabled?` antes de ejecutarse.

**Implementación:**
```ruby
class PluginInstance
  def enabled?
    @enabled_setting ? SiteSetting.get(@enabled_setting) : true
  end
end

# En el registry (filtered_register):
values.filter_map { |entry| entry[:value] if entry[:plugin].enabled? }

# En add_to_class:
klass.define_method(attr) do |*args|
  send(hidden_method, *args) if plugin.enabled?
end
```

**Ventaja:** Habilitar/deshabilitar es instantáneo sin reiniciar. Permite A/B testing de features.

**Limitación:** Las rutas y migraciones no se revierten. Es una desactivación "soft".

---

## Patrón 12: Aislamiento por Namespace + Rails Engine

**Idea:** Cada plugin vive en su propio módulo Ruby y tiene su propio `Rails::Engine` con `isolate_namespace`. Esto evita colisiones de nombres y mantiene las rutas del plugin separadas.

```ruby
module ::MyPlugin
  PLUGIN_NAME = "my-plugin"

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace MyPlugin
    config.autoload_paths << File.join(config.root, "lib")
  end
end
```

**Beneficios de `isolate_namespace`:**
- Los helpers del plugin no se mezclan con los del core
- Las rutas del plugin tienen su propio scope
- Los URL helpers son `my_plugin.examples_path` en lugar de `examples_path`

---

## Patrón 13: Event Bus Minimalista

**Idea:** Un pub/sub simple con Hash de Sets es suficiente para la mayoría de casos. No necesitas una librería externa.

```ruby
class AppEvent
  def self.events
    @events ||= Hash.new { |h, k| h[k] = Set.new }
  end

  def self.on(event_name, &block)
    events[event_name] << block
    block # retornar el bloque permite hacer off fácilmente
  end

  def self.off(event_name, &block)
    events[event_name].delete(block)
  end

  def self.trigger(event_name, *args, **kwargs)
    events[event_name].each { |handler| handler.call(*args, **kwargs) }
  end
end
```

**Decisión de Discourse:** Usar `Set` en lugar de `Array` evita registrar el mismo handler dos veces (importante en hot-reload).

---

## Patrón 14: Protección contra Errores de Inicialización

**Idea:** Envolver la inicialización de plugins en un guard que identifica qué plugin causó el error y termina el proceso con un mensaje claro.

```ruby
def self.initialization_guard(&block)
  block.call
rescue => error
  plugin_path = identify_plugin_from_backtrace(error.backtrace)
  if plugin_path
    STDERR.puts "** INCOMPATIBLE PLUGIN **\n#{plugin_path}\n#{error}"
    exit 1
  else
    raise
  end
end

def self.identify_plugin_from_backtrace(backtrace)
  plugins_dir = Rails.root.join("plugins")
  backtrace.lazy.map do |line|
    path = line.split(":").first
    Pathname.new(path).ascend.find { |p| p.parent == plugins_dir }
  end.first
end
```

**Ventaja:** En lugar de un stack trace críptico, el operador ve exactamente qué plugin está roto y cómo solucionarlo.

---

## Resumen de Decisiones Arquitectónicas Clave

| Decisión | Alternativa descartada | Razón |
|----------|----------------------|-------|
| Convención de carpetas para descubrimiento | Registro explícito en config | Zero-config para instalar plugins |
| `define_filtered_register` con `plugin.enabled?` | Eliminar registros al deshabilitar | Habilitar/deshabilitar sin reiniciar |
| `reloadable_patch` + `to_prepare` | Patches solo en boot | Hot-reload en desarrollo |
| `Module#prepend` para freedom patches | `alias_method` | `super` funciona, no hay colisiones de nombres |
| Árbol de rutas intermedio (frontend) | Modificar el router directamente | Los routers SPA no son extensibles post-definición |
| Outlets declarativos en plantillas | Hooks imperativos | Los plugins no necesitan conocer el core |
| Modifier pipeline (valor de retorno) | Eventos (fire and forget) | Múltiples plugins pueden cooperar en una decisión |
| `Rails::Engine` con `isolate_namespace` | Namespace manual | Autoloading, rutas y helpers aislados automáticamente |
| Metadatos en comentarios del header | Archivo YAML separado | Un solo archivo, no hay sincronización |
| Dos fases (parse + activate) | Activación directa | Mostrar info de plugins antes de activarlos |

### Citations

**File:** lib/plugin/instance.rb (L96-105)
```ruby
  def self.find_all(parent_path)
    allowed = GlobalSetting.plugins_to_load
    [].tap do |plugins|
      # also follows symlinks - http://stackoverflow.com/q/357754
      Dir["#{parent_path}/*/plugin.rb"].sort.each do |path|
        next if allowed && !allowed.include?(File.basename(File.dirname(path)))
        plugins << parse_from_source(path)
      end
    end
  end
```

**File:** lib/plugin/instance.rb (L182-185)
```ruby
  def enabled?
    return false if !configurable?
    @enabled_site_setting ? SiteSetting.get(@enabled_site_setting) : true
  end
```

**File:** lib/plugin/instance.rb (L193-240)
```ruby
  def add_to_serializer(
    serializer,
    attr,
    deprecated_respect_plugin_enabled = nil,
    respect_plugin_enabled: true,
    include_condition: nil,
    &block
  )
    if !deprecated_respect_plugin_enabled.nil?
      Discourse.deprecate(
        "add_to_serializer's respect_plugin_enabled argument should be passed as a keyword argument",
      )
      respect_plugin_enabled = deprecated_respect_plugin_enabled
    end

    if attr.to_s.starts_with?("include_")
      Discourse.deprecate(
        "add_to_serializer should not be used to directly override include_*? methods. Use the include_condition keyword argument instead",
      )
    end

    reloadable_patch do |plugin|
      base =
        begin
          "#{serializer.to_s.classify}Serializer".constantize
        rescue StandardError
          "#{serializer}Serializer".constantize
        end

      # we have to work through descendants cause serializers may already be baked and cached
      ([base] + base.descendants).each do |klass|
        unless attr.to_s.start_with?("include_")
          klass.attributes(attr)

          if respect_plugin_enabled || include_condition
            # Don't include serialized methods if the plugin is disabled
            klass.public_send(:define_method, "include_#{attr}?") do
              next false if respect_plugin_enabled && !plugin.enabled?
              next instance_exec(&include_condition) if include_condition
              true
            end
          end
        end

        klass.public_send(:define_method, attr, &block)
      end
    end
  end
```

**File:** lib/plugin/instance.rb (L448-463)
```ruby
  def add_to_class(class_name, attr, &block)
    reloadable_patch do |plugin|
      klass =
        begin
          class_name.to_s.classify.constantize
        rescue StandardError
          class_name.to_s.constantize
        end
      hidden_method_name = :"#{attr}_without_enable_check"
      klass.public_send(:define_method, hidden_method_name, &block)

      klass.public_send(:define_method, attr) do |*args, **kwargs|
        public_send(hidden_method_name, *args, **kwargs) if plugin.enabled?
      end
    end
  end
```

**File:** lib/plugin/instance.rb (L663-666)
```ruby
  # A proxy to `DiscourseEvent.on` which does nothing if the plugin is disabled
  def on(event_name, &block)
    DiscourseEvent.on(event_name) { |*args, **kwargs| block.call(*args, **kwargs) if enabled? }
  end
```

**File:** lib/plugin/instance.rb (L772-774)
```ruby
  def register_locale(locale, opts = {})
    locales << [locale, opts]
  end
```

**File:** lib/plugin/instance.rb (L853-888)
```ruby
  def activate!
    instance_eval File.read(path), path
    if auto_assets = generate_automatic_assets!
      assets.concat(auto_assets)
    end

    register_assets! if assets.present?
    register_locales!
    register_service_workers!

    seed_data.each { |key, value| DiscoursePluginRegistry.register_seed_data(key, value) }

    # Automatically include rake tasks
    Rake.add_rakelib(File.dirname(path) + "/lib/tasks")

    # Automatically include migrations
    migration_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths
    migration_paths << File.dirname(path) + "/db/migrate"

    unless Discourse.skip_post_deployment_migrations?
      migration_paths << "#{File.dirname(path)}/#{Discourse::DB_POST_MIGRATE_PATH}"
    end

    public_data = File.dirname(path) + "/public"
    if Dir.exist?(public_data)
      target = Rails.root.to_s + "/public/plugins/"

      Discourse::Utils.execute_command("mkdir", "-p", target)
      target << name.gsub(/\s/, "_")

      Discourse::Utils.atomic_ln_s(public_data, target)
    end

    write_extra_js!
    ensure_images_symlink!
  end
```

**File:** lib/plugin/instance.rb (L954-972)
```ruby
  def extend_list_method(klass, method, new_attributes)
    register_name = [klass, method].join("_").underscore
    DiscoursePluginRegistry.define_filtered_register(register_name)
    DiscoursePluginRegistry.public_send(
      "register_#{register_name.singularize}",
      new_attributes,
      self,
    )

    original_method_alias = "__original_#{method}__"
    return if klass.respond_to?(original_method_alias)
    reloadable_patch do
      klass.singleton_class.alias_method(original_method_alias, method)
      klass.define_singleton_method(method) do
        public_send(original_method_alias) |
          DiscoursePluginRegistry.public_send(register_name).flatten
      end
    end
  end
```

**File:** lib/plugin/instance.rb (L1598-1602)
```ruby
  def register_assets!
    assets.each do |asset, opts, plugin_directory_name|
      DiscoursePluginRegistry.register_asset(asset, opts, plugin_directory_name)
    end
  end
```

**File:** lib/plugin/instance.rb (L1696-1706)
```ruby
  def reloadable_patch(plugin = self)
    if Rails.env.development? && defined?(ActiveSupport::Reloader)
      ActiveSupport::Reloader.to_prepare do
        # reload the patch
        yield plugin
      end
    end

    # apply the patch
    yield plugin
  end
```

**File:** app/models/global_setting.rb (L388-412)
```ruby
  def self.load_plugins?
    load_plugins_filter != :none
  end

  def self.plugins_to_load
    filter = load_plugins_filter
    filter.is_a?(Array) ? filter : nil
  end

  # Returns `:all`, `:none`, or an array of plugin directory names.
  def self.load_plugins_filter
    case ENV["LOAD_PLUGINS"]
    when "0"
      :none
    when "1"
      :all
    when nil, ""
      Rails.env.test? ? :none : :all
    else
      unless Rails.env.local?
        raise "LOAD_PLUGINS=#{ENV["LOAD_PLUGINS"].inspect} is only supported in development/test"
      end
      ENV["LOAD_PLUGINS"].split(",").map { |p| File.basename(p.strip) }.reject(&:empty?)
    end
  end
```

**File:** lib/discourse_plugin_registry.rb (L20-56)
```ruby
  def self.define_register(register_name, type)
    return if respond_to?(register_name)
    @@register_names << register_name

    define_singleton_method(register_name) do
      instance_variable_get(:"@#{register_name}") ||
        instance_variable_set(:"@#{register_name}", type.new)
    end

    define_method(register_name) { self.class.public_send(register_name) }
  end

  # Plugins often need to add values to a list, and we need to filter those
  # lists at runtime to ignore values from disabled plugins. Unlike define_register,
  # the type of the register cannot be defined, and is always Array.
  #
  # Create a new register (see `define_register`) with some additions:
  #   - Register is created in a class variable using the specified name/type
  #   - Defines singleton method to access the register
  #   - Defines instance method as a shortcut to the singleton method
  #   - Automatically deletes the register on registry.reset!
  def self.define_filtered_register(register_name)
    return if respond_to?(register_name)
    define_register(register_name, Array)

    singleton_class.alias_method :"_raw_#{register_name}", :"#{register_name}"

    define_singleton_method(register_name) do
      public_send(:"_raw_#{register_name}").filter_map { |h| h[:value] if h[:plugin].enabled? }.uniq
    end

    define_singleton_method("register_#{register_name.to_s.singularize}") do |value, plugin|
      public_send(:"_raw_#{register_name}") << { plugin: plugin, value: value }
    end

    yield(self) if block_given?
  end
```

**File:** lib/discourse_plugin_registry.rb (L274-310)
```ruby
  def self.register_modifier(plugin_instance, name, &blk)
    @modifiers ||= {}
    modifiers = @modifiers[name] ||= []
    modifiers << [plugin_instance, blk]
  end

  def self.unregister_modifier(plugin_instance, name, &blk)
    raise "unregister_modifier can only be used in tests" if !Rails.env.test?

    modifiers_for_name = @modifiers&.[](name)
    raise "no #{name} modifiers found" if !modifiers_for_name

    i = modifiers_for_name.find_index { |info| info == [plugin_instance, blk] }
    raise "no modifier found for that plugin/block combination" if !i

    modifiers_for_name.delete_at(i)
  end

  def self.apply_modifier(name, arg, *more_args)
    return arg if !@modifiers

    registered_modifiers = @modifiers[name]
    return arg if !registered_modifiers

    # iterate as fast as possible to minimize cost (avoiding each)
    # also erases one stack frame
    length = registered_modifiers.length
    index = 0
    while index < length
      plugin_instance, block = registered_modifiers[index]
      arg = block.call(arg, *more_args) if plugin_instance.enabled?

      index += 1
    end

    arg
  end
```

**File:** config/application.rb (L126-127)
```ruby
    config.i18n.load_path += Dir["#{Rails.root.join("plugins/*/config/locales/*.yml")}"]

```

**File:** config/application.rb (L197-230)
```ruby
    if Rails.env.test? && GlobalSetting.load_plugins?
      Discourse.activate_plugins!
    elsif GlobalSetting.load_plugins?
      Plugin.initialization_guard { Discourse.activate_plugins! }
    end

    # Use discourse-fonts gem to symlink fonts and generate .scss file
    fonts_path = File.join(config.root, "public/fonts")
    if !File.exist?(fonts_path) || File.realpath(fonts_path) != DiscourseFonts.path_for_fonts
      File.delete(fonts_path) if File.exist?(fonts_path)
      Discourse::Utils.atomic_ln_s(DiscourseFonts.path_for_fonts, fonts_path)
    end

    require "stylesheet/manager"
    require "svg_sprite"

    config.after_initialize do
      # Load plugins
      Plugin.initialization_guard { Discourse.plugins.each(&:notify_after_initialize) }

      # we got to clear the pool in case plugins connect
      ActiveRecord::Base.connection_handler.clear_active_connections!

      # Mailers and controllers may have been patched by plugins and when the
      # application is eager loaded, the list of public methods is cached.
      # We need to invalidate the existing caches, otherwise the new actions
      # won’t be seen by Rails.
      if Rails.configuration.eager_load
        AbstractController::Base.descendants.each do |controller|
          controller.clear_action_methods!
          controller.action_methods
        end
      end

```

**File:** lib/discourse.rb (L345-372)
```ruby
  def self.activate_plugins!
    @plugins = []
    @plugins_by_name = {}
    Plugin::Instance
      .find_all("#{Rails.root.join("plugins")}")
      .each do |p|
        v = p.metadata.required_version || Discourse::VERSION::STRING
        if Discourse.has_needed_version?(Discourse::VERSION::STRING, v)
          p.activate!
          @plugins << p
          @plugins_by_name[p.name] = p

          # The plugin directory name and metadata name should match, but that
          # is not always the case
          dir_name = p.path.split("/")[-2]
          if p.name != dir_name
            STDERR.puts "Plugin name is '#{p.name}', but plugin directory is named '#{dir_name}'"
            # Plugins are looked up by directory name in SiteSettingExtension
            # because SiteSetting.load_settings uses directory name as plugin
            # name. We alias the two names just to make sure the look up works
            @plugins_by_name[dir_name] = p
          end
        else
          STDERR.puts "Could not activate #{p.metadata.name}, discourse does not meet required version (#{v})"
        end
      end
    DiscourseEvent.trigger(:after_plugin_activation)
  end
```

**File:** lib/plugin.rb (L4-60)
```ruby
  def self.initialization_guard(&block)
    block.call
  rescue => error
    plugins_directory = Rails.root + "plugins"

    if error.backtrace && error.backtrace_locations
      plugin_path =
        error
          .backtrace_locations
          .lazy
          .map do |location|
            resolved_path = location.absolute_path || location.path
            next if resolved_path.nil?
            Pathname.new(resolved_path).ascend.lazy.find { |path| path.parent == plugins_directory }
          end
          .next

      raise unless plugin_path

      stack_trace =
        error
          .backtrace
          .each_with_index
          .inject([]) do |messages, (line, index)|
            if index == 0
              messages << "#{line}: #{error} (#{error.class})"
            else
              messages << "\t#{index}: from #{line}"
            end
          end
          .reverse
          .join("\n")

      STDERR.puts <<~TEXT
          #{stack_trace}

          ** INCOMPATIBLE PLUGIN **

          You are unable to start Discourse due to errors in the plugin at
          #{plugin_path}

          Please try removing this plugin and rebuilding again!
        TEXT
    else
      STDERR.puts <<~TEXT
          ** PLUGIN FAILURE **

          You are unable to start Discourse due to this error during plugin
          initialization:

          #{error}

          #{error.backtrace.join("\n")}
        TEXT
    end
    exit 1
  end
```

**File:** lib/discourse_event.rb (L1-51)
```ruby
# frozen_string_literal: true

# This is meant to be used by plugins to trigger and listen to events
# So we can execute code when things happen.
class DiscourseEvent
  # Defaults to a hash where default values are empty sets.
  def self.events
    @events ||= Hash.new { |hash, key| hash[key] = Set.new }
  end

  def self.trigger(event_name, *args, continue_on_error: false, **kwargs)
    events[event_name].each do |event|
      event.call(*args, **kwargs)
    rescue => e
      raise unless continue_on_error
      Discourse.warn_exception(e, message: "on(:#{event_name}) handler error")
    end
  end

  def self.on(event_name, &block)
    case event_name
    when :user_badge_removed
      Discourse.deprecate(
        "The :user_badge_removed event is deprecated. Please use :user_badge_revoked instead",
        since: "3.1.0.beta5",
        drop_from: "3.2.0.beta1",
        output_in_test: true,
      )
    when :post_notification_alert
      Discourse.deprecate(
        "The :post_notification_alert event is deprecated. Please use :push_notification instead",
        since: "3.2.0.beta1",
        drop_from: "3.3.0.beta1",
        output_in_test: true,
      )
    else
      # ignore
    end

    events[event_name] << block
  end

  def self.off(event_name, &block)
    raise ArgumentError.new "DiscourseEvent.off must reference a block" if block.nil?
    events[event_name].delete(block)
  end

  def self.all_off(event_name)
    events.delete(event_name)
  end
end
```

**File:** frontend/discourse/app/components/plugin-outlet.gjs (L70-145)
```text
/**
 * A plugin outlet is an extension point for templates where other templates can
 * be inserted by plugins.
 *
 * ## Standard vs wrapper outlets
 *
 * A **standard outlet** is an empty slot where connectors are inserted:
 *
 * ```handlebars
 * <PluginOutlet @name="above-footer" />
 * ```
 *
 * A **wrapper outlet** wraps existing content by providing a block. When a
 * connector is registered, it replaces the wrapped content. The outlet also
 * automatically creates `__before` and `__after` sub-outlets that allow
 * multiple connectors to render before or after the wrapped content without
 * replacing it:
 *
 * ```handlebars
 * <PluginOutlet @name="discovery-list-area">
 *   <div class="default-content">This is the default content</div>
 * </PluginOutlet>
 * ```
 *
 * In this example, connectors can target:
 * - `discovery-list-area` to replace the default content
 * - `discovery-list-area__before` to render before it
 * - `discovery-list-area__after` to render after it
 *
 * ## Rendering connectors
 *
 * There are two ways to render content in a plugin outlet:
 *
 * ### 1. Plugin API (`api.renderInOutlet`)
 *
 * Register a component programmatically using the Plugin API:
 *
 * ```javascript
 * import MyComponent from "discourse/plugins/my-plugin/components/my-component";
 * api.renderInOutlet("evil-trout", MyComponent);
 * ```
 *
 * Or inline with gjs:
 *
 * ```javascript
 * api.renderInOutlet("evil-trout", <template><b>Hello World</b></template>);
 * ```
 *
 * For wrapper outlets, use `api.renderBeforeWrapperOutlet()` and
 * `api.renderAfterWrapperOutlet()` to render content before or after the
 * wrapped content without replacing it:
 *
 * ```javascript
 * api.renderBeforeWrapperOutlet("discovery-list-area", BeforeComponent);
 * api.renderAfterWrapperOutlet("discovery-list-area", AfterComponent);
 * ```
 *
 * ### 2. File-based connectors
 *
 * Create a template file in the `connectors/<outlet-name>/` directory:
 *
 * `plugins/my-plugin/assets/javascripts/discourse/connectors/evil-trout/hello.gjs`
 *
 * ```gjs
 * <template><b>Hello World</b></template>
 * ```
 *
 * This will render `<b>Hello World</b>` in every `<PluginOutlet @name="evil-trout" />`.
 *
 * For wrapper outlets, use the `__before` and `__after` suffixes in the
 * connector directory name:
 *
 * `plugins/my-plugin/assets/javascripts/discourse/connectors/discovery-list-area__before/my-connector.gjs`
 * `plugins/my-plugin/assets/javascripts/discourse/connectors/discovery-list-area__after/my-connector.gjs`
 *
 * ## Args
```

**File:** frontend/discourse/app/components/plugin-outlet.gjs (L631-683)
```text
    {{~#if (this.connectorsExist hasBlock=(has-block))~}}
      {{~#if (has-block)~}}
        <PluginOutlet
          @name={{concat @name "__before"}}
          @aliases={{this.aliasesForBefore}}
          @connectorTagName={{this.connectorTagNameForBefore}}
          @outletArgs={{this.outletArgsWithDeprecations}}
        />
      {{~/if~}}

      {{~#each (this.getConnectors hasBlock=(has-block)) as |c|~}}
        {{~#if c.componentClass~}}
          {{~#let
            (this.safeCurryComponent
              c.componentClass this.outletArgsWithDeprecations
            )
            as |CurriedComponent|
          ~}}
            <CurriedComponent
              @outletArgs={{this.outletArgsWithDeprecations}}
            >{{yield}}</CurriedComponent>
          {{~/let~}}
        {{~else if @defaultGlimmer~}}
          <c.templateOnly
            @outletArgs={{this.outletArgsWithDeprecations}}
          >{{yield}}</c.templateOnly>
        {{~else~}}
          <PluginConnector
            @connector={{c}}
            @args={{this.outletArgs}}
            @deprecatedArgs={{@deprecatedArgs}}
            @outletArgs={{this.outletArgsWithDeprecations}}
            @tagName={{or @connectorTagName ""}}
            @layout={{c.template}}
            class={{c.classicClassNames}}
          >{{yield}}</PluginConnector>
        {{~/if~}}
      {{~else~}}
        {{yield}}
      {{~/each~}}

      {{~#if (has-block)~}}
        <PluginOutlet
          @name={{concat @name "__after"}}
          @aliases={{this.aliasesForAfter}}
          @connectorTagName={{this.connectorTagNameForAfter}}
          @outletArgs={{this.outletArgsWithDeprecations}}
        />
      {{~/if~}}
    {{~else~}}
      {{yield}}
    {{~/if~}}
  </template>
```

**File:** docs/developer-guides/docs/04-plugins/02-plugin-outlet.md (L37-62)
```markdown
### Connecting to a Plugin Outlet

Once you've found the plugin outlet you want to add to, you have to write a `connector` for it. A connector is a `.gjs` component whose filename includes `connectors/<outlet name>` in its path.

For example, if the Discourse template has:

```hbs
<PluginOutlet @name="evil-trout" />
```

Then any `.gjs` files you create in the `connectors/evil-trout` directory
will automatically be appended. So if you created the file:

`plugins/hello/assets/javascripts/discourse/connectors/evil-trout/hello.gjs`

With the contents:

```gjs
<template>
  <b>Hello World</b>
</template>
```

Discourse would insert `<b>Hello World</b>` at that point in the template.

Note that we called the file `hello.gjs` -- The filename (as opposed to the directory name) does not matter, but it must be unique across every plugin. It's useful to name it something descriptive of what you are extending it to do. This will make debugging easier in the future.
```

**File:** frontend/discourse/app/lib/plugin-api.gjs (L1129-1131)
```text
  renderInOutlet(outletName, klass) {
    extraConnectorComponent(outletName, klass);
  }
```

**File:** frontend/discourse/app/lib/plugin-api.gjs (L3635-3668)
```text
function getPluginApi() {
  const owner = getOwnerWithFallback(this);
  let pluginApi = owner.lookup("plugin-api:main");

  if (!pluginApi) {
    pluginApi = new _PluginApi(owner);
    owner.registry.register("plugin-api:main", pluginApi, {
      instantiate: false,
    });
  } else {
    // If we are re-using an instance, make sure the container is correct
    pluginApi.container = owner;
  }

  return pluginApi;
}

/**
 * Executes the provided callback function with the `PluginApi` object.
 *
 * @param {(api: _PluginApi, opts: object) => any} apiCodeCallback - The callback function to execute
 * @param {object} [opts] - Optional additional options to pass to the callback function.
 * @returns {any} The result of the `callback` function, if executed
 */
export function withPluginApi(apiCodeCallback, opts) {
  if (typeof arguments[0] === "string") {
    // Old path. First argument is the version string. Silently ignore.
    [, apiCodeCallback, opts] = arguments;
  }

  opts = opts || {};

  return apiCodeCallback(getPluginApi(), opts);
}
```

**File:** frontend/discourse/app/components/plugin-connector.js (L22-103)
```javascript
export default class PluginConnector extends Component {
  init() {
    super.init(...arguments);

    if (this.args) {
      Object.keys(this.args).forEach((key) => {
        defineProperty(
          this,
          key,
          computed(`args.${key}`, function () {
            return this.args[key];
          })
        );
      });
    }

    const connectorInfo = {
      outletName: this.connector?.outletName,
      connectorName: this.connector?.connectorName,
      classModuleName: this.connector?.classModuleName,
      templateModule: this.connector?.templateModule,
      layoutName: this.layoutName,
    };

    if (this.deprecatedArgs) {
      Object.keys(this.deprecatedArgs).forEach((key) => {
        defineProperty(
          this,
          key,
          computed("deprecatedArgs", function () {
            return deprecatedArgumentValue(this.deprecatedArgs[key], {
              ...connectorInfo,
              argumentName: key,
            });
          })
        );
      });
    }

    const connectorClass = this.connector.connectorClass;
    this.set("actions", connectorClass?.actions);

    if (this.actions) {
      for (const [name, action] of Object.entries(this.actions)) {
        this.set(name, action.bind(this));
      }
    }

    const merged = buildArgsWithDeprecations(
      this.args,
      this.deprecatedArgs,
      connectorInfo
    );
    connectorClass?.setupComponent?.call(this, merged, this);
  }

  didReceiveAttrs() {
    super.didReceiveAttrs(...arguments);

    this._decoratePluginOutlets();
  }

  @afterRender
  _decoratePluginOutlets() {
    (_decorators[this.connector.outletName] || []).forEach((dec) =>
      dec(this.element, this.args)
    );
  }

  willDestroyElement() {
    super.willDestroyElement(...arguments);

    const connectorClass = this.connector.connectorClass;
    connectorClass?.teardownComponent?.call(this, this);
  }

  send(name, ...args) {
    const connectorClass = this.connector.connectorClass;
    const action = connectorClass?.actions?.[name];
    return action ? action.call(this, ...args) : super.send(name, ...args);
  }
}
```

**File:** lib/freedom_patches/propshaft_patches.rb (L1-25)
```ruby
# frozen_string_literal: true

Propshaft::Helper.prepend(
  Module.new do
    def compute_asset_path(path, options = {})
      attempts = 0
      begin
        super
      rescue Propshaft::MissingAssetError => e
        if Rails.env.test?
          # Assets might not be compiled in test mode. Just return a fake path
          "/assets/#{path}"
        elsif Rails.env.development?
          # Ember-cli might've replaced the assets
          Rails.application.assets.load_path.send(:clear_cache)
          attempts += 1
          retry if attempts < 3
          raise e
        else
          raise e
        end
      end
    end
  end,
)
```

**File:** config/initializers/000-zeitwerk.rb (L55-62)
```ruby
Rails.autoloaders.main.ignore(
  "lib/tasks",
  "lib/generators",
  "lib/freedom_patches",
  "lib/i18n/backend",
  "lib/release_utils",
  "lib/pitchfork_logstash_patch.rb",
)
```

**File:** lib/plugin/js_manager.rb (L46-163)
```ruby
    def compile!
      log "Compiling #{Discourse.plugins.count} plugins..."
      start = Time.now

      if !GlobalSetting.mini_racer_single_threaded && AssetProcessor.booted?
        raise "Cannot fork Plugin::JsManager for parallel compilation because AssetProcessor is already booted."
      end

      parallel_count = [Etc.nprocessors, 4].min
      AssetProcessor.timeout = 120_000

      Parallel.each(Discourse.plugins, in_processes: parallel_count) do |plugin|
        compile_js_bundle(plugin)
      end

      log "Finished initial compilation of plugins in #{(Time.now - start).round(2)}s"
    end

    def compile_js_bundle(plugin)
      base_output_dir = "#{Rails.root.join("app/assets/generated/#{plugin.directory_name}")}"
      js_dir = "#{base_output_dir}/js/plugins"
      map_dir = "#{base_output_dir}/map/plugins"

      entrypoints = { "main" => "assets/javascripts", "admin" => "admin/assets/javascripts" }
      entrypoints["test"] = "test/javascripts" if Rails.env.local?

      tree = {}
      entrypoints_config = {}

      entrypoints.each do |name, js_path|
        js_base = "#{plugin.directory}/#{js_path}"

        files = Dir.glob("**/*", base: js_base)

        next if files.empty?

        entrypoints_config[name] = { modules: [] }

        files.sort.each do |file|
          full_path = File.join(js_base, file)
          if File.file?(full_path)
            normalized_file_path = file.sub(/\.js\.es6$/, ".js")
            content = File.read(full_path)
            content = AssetProcessor.append_es6_deprecation(content, file) if file.end_with?(
              ".js.es6",
            )
            tree[normalized_file_path] = content
            if name == "test" && file.match(%r{/(acceptance|integration|unit)/})
              if file.match?(/-test\.g?js$/)
                entrypoints_config[name][:modules] << normalized_file_path
              end
            else
              entrypoints_config[name][:modules] << normalized_file_path
            end
          end
        end
      end

      hex_digest =
        Digest::SHA1.hexdigest(
          [
            *tree.keys,
            *tree.values,
            AssetProcessor::BASE_COMPILER_VERSION,
            AssetProcessor.ember_version,
            minify?.to_s,
            plugin.name,
          ].join,
        )
      base36_digest = hex_digest.to_i(16).to_s(36).first(8)

      filename_prefix = "#{plugin.directory_name}_"
      filename_suffix = "-#{base36_digest}.digested"

      expected_entrypoints =
        entrypoints_config.keys.map do |name|
          "#{js_dir}/#{filename_prefix}#{name}#{filename_suffix}.js"
        end

      files_exist = expected_entrypoints.all? { |path| File.exist?(path) }

      if !cache? || !files_exist
        compiler =
          Plugin::JsCompiler.new(
            plugin.name,
            minify: minify?,
            tree: tree,
            entrypoints: entrypoints_config,
            filename_prefix:,
            filename_suffix:,
          )
        result = compiler.compile!

        FileUtils.mkdir_p(js_dir)
        FileUtils.mkdir_p(map_dir)

        manifest = {}
        result.each do |file_name, info|
          code = info["code"]
          code += "\n//# sourceMappingURL=../../map/plugins/#{file_name}.map\n" if info["map"]
          File.write("#{js_dir}/#{file_name}", code)

          File.write("#{map_dir}/#{file_name}.map", info["map"]) if info["map"]

          if info["isEntry"]
            manifest[info["name"]] = { fileName: file_name, imports: info["imports"] }
          end
        end

        File.write("#{base_output_dir}/manifest.json", JSON.pretty_generate(manifest))
      end

      # Delete any old versions
      Dir
        .glob("#{base_output_dir}/*/*/*")
        .reject { |path| path.include?(filename_suffix) || path.include?("_extra") }
        .each { |path| FileUtils.rm_rf(path) }
    end
```

**File:** docs/developer-guides/docs/04-plugins/11-rails-autoloading.md (L30-53)
```markdown
Now create `{plugin}/lib/my_plugin_module/engine.rb`:

```rb
module ::MyPluginModule
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace MyPluginModule
  end
end
```

Important things to note:

1. In plugin.rb, you must include `::` before your module name to define it in the root namespace (otherwise, it would be defined under `Plugin::Instance`)
1. `require_relative "lib/.../engine"` must be in the root of the `plugin.rb` file, not inside an `after_initialize` block

1. Putting the engine in its own file under `lib/` is important. Defining it directly in the `plugin.rb` file will not work. (Rails uses the presence of a `lib/` directory to determine the root of the engine)

1. The file path should include the module name, according to the [Zeitwerk rules](https://github.com/fxn/zeitwerk#file-structure)

1. The `engine_name` is used as the prefix for rake tasks and any routes defined by the engine ([:link: rails docs](https://api.rubyonrails.org/classes/Rails/Engine.html#class-Rails::Engine-label-Engine+name))

1. `isolate_namespace` helps to prevent things leaking between core and the plugin ([:link: Rails docs](https://api.rubyonrails.org/classes/Rails/Engine.html#class-Rails::Engine-label-Isolated+Engine))

```

**File:** docs/developer-guides/docs/04-plugins/11-rails-autoloading.md (L56-70)
```markdown
The engine will now autoload all files in `{plugin}/app/{type}/*`. For example, we can define a controller

`{plugin}/app/controllers/my_plugin_module/examples_controller.rb`

```rb
module ::MyPluginModule
  class ExamplesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    def index
      render json: { hello: "world" }
    end
  end
end
```
```

**File:** docs/developer-guides/docs/04-plugins/11-rails-autoloading.md (L76-91)
```markdown
## 3. Defining routes on the plugin's engine

Create a `{plugin}/config/routes.rb` file

```rb
MyPluginModule::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw do
  mount ::MyPluginModule::Engine, at: "my-plugin"
end
```

This file will be automatically loaded by the engine, and changes will take effect without a server restart. In this case, the controller action would be available at `/my-plugin/examples.json`.
```

**File:** frontend/discourse/app/mapping-router.js (L107-143)
```javascript
export function mapRoutes() {
  const tree = new RouteNode("root");
  const extras = [];

  // If a module is defined as `route-map` in discourse or a plugin, its routes
  // will be built automatically. You can supply a `resource` property to
  // automatically put it in that resource, such as `admin`. That way plugins
  // can define admin routes.
  Object.keys(requirejs.entries).forEach(function (key) {
    if (/route-map$/.test(key)) {
      let module = requirejs(key, null, null, true);
      if (!module || !module.default) {
        throw new Error(key + " must export a route map.");
      }

      const mapObj = module.default;
      if (typeof mapObj === "function") {
        tree.extract(mapObj);
      } else {
        extras.push(mapObj);
      }
    }
  });

  extras.forEach((extra) => {
    let node = tree.findPath(extra.resource);
    if (node) {
      node.extract(extra.map);
    }
  });

  return class extends BareRouter {
    rootURL = getURL("/");
  }.map(function () {
    tree.mapRoutes(this);
    this.route("unknown", { path: "*path" });
  });
```

**File:** lib/freedom_patches/translate_accelerator.rb (L1-60)
```ruby
# frozen_string_literal: true

# This patch performs 2 functions
#
# 1. It caches all translations which drastically improves
#    translation performance in an LRU cache
#
# 2. It patches I18n so it only loads the translations it needs
#    on demand
#
# This patch depends on the convention that locale yml files must be named [locale_name].yml

module I18n
  # this accelerates translation a tiny bit (halves the time it takes)
  class << self
    alias_method :translate_no_cache, :translate
    alias_method :exists_no_cache?, :exists?
    alias_method :reload_no_cache!, :reload!
    alias_method :locale_no_cache=, :locale=

    LRU_CACHE_SIZE = 400

    def init_accelerator!(overrides_enabled: true)
      @overrides_enabled = overrides_enabled
      reserve_key(:overrides)
      execute_reload
    end

    def reload!
      @requires_reload = true
    end

    LOAD_MUTEX = Mutex.new

    def load_locale(locale)
      locale = locale.to_sym
      LOAD_MUTEX.synchronize do
        return if @loaded_locales.include?(locale)

        if @loaded_locales.empty?
          # load all rb files
          I18n.backend.load_translations(I18n.load_path.grep(/\.rb\z/))

          # load plural rules from plugins
          DiscoursePluginRegistry.locales.each do |plugin_locale, options|
            if options[:plural]
              I18n.backend.store_translations(plugin_locale, i18n: { plural: options[:plural] })
            end
          end
        end

        # load it
        I18n.backend.load_translations(I18n.load_path.grep(/\.#{Regexp.escape locale}\.yml\z/))

        if Discourse.allow_dev_populate? || Rails.env.local?
          I18n.backend.load_translations(
            I18n.load_path.grep(%r{.*faker.*/#{Regexp.escape locale}\.yml\z}),
          )
          I18n.backend.load_translations(
            I18n.load_path.grep(%r{.*faker.*/#{Regexp.escape locale}/.*\.yml\z}),
```

**File:** lib/plugin/metadata.rb (L11-21)
```ruby
  FIELDS = %i[name about version authors contact_emails url required_version meta_topic_id label]
  attr_accessor(*FIELDS)

  MAX_FIELD_LENGTHS = {
    name: 75,
    about: 350,
    authors: 200,
    contact_emails: 200,
    url: 500,
    label: 20,
  }
```

**File:** frontend/discourse/app/lib/api.js (L1-24)
```javascript
// @ts-check
import { withPluginApi } from "discourse/lib/plugin-api";

let _apiInitializerId = 0;

/**
 * Define an initializer which will execute a callback with a PluginApi object.
 *
 * @param {(api: import("./plugin-api.gjs").PluginApi, opts: object) => any} apiCodeCallback - The callback function to execute
 * @param {object} [opts] - Optional additional options to pass to the callback function.
 */
export function apiInitializer(apiCodeCallback, opts) {
  if (typeof arguments[0] === "string") {
    // Old path. First argument is the version string. Silently ignore.
    [, apiCodeCallback, opts] = arguments;
  }
  return {
    name: `api-initializer${_apiInitializerId++}`,
    after: "inject-objects",
    initialize() {
      return withPluginApi(apiCodeCallback, opts);
    },
  };
}
```

**File:** frontend/discourse/app/lib/transformer.js (L303-372)
```javascript
export function applyValueTransformer(
  transformerName,
  defaultValue,
  context,
  opts = { mutable: false }
) {
  const normalizedTransformerName = _normalizeTransformerName(
    transformerName,
    transformerTypes.VALUE
  );

  const prefix = () => `${consolePrefix()} applyValueTransformer`.trim();

  if (!transformerNameExists(normalizedTransformerName)) {
    throw new Error(
      `${prefix()}: transformer name "${transformerName}" does not exist. ` +
        "Was the transformer name properly added? Is the transformer name correct? Is the type equals VALUE? " +
        "applyValueTransformer can only be used with VALUE transformers."
    );
  }

  if (
    typeof (context ?? undefined) !== "undefined" &&
    !(
      typeof context === "object" &&
      (context.constructor === Object || context.constructor === undefined)
    )
  ) {
    throw (
      `${prefix()}("${transformerName}", ...): context must be a simple JS object/an Ember hash or nullish.\n` +
      "Avoid passing complex objects in the context, like for example, component instances or objects that carry " +
      "mutable state directly. This can induce users to registry transformers with callbacks causing side effects " +
      "and mutating the context directly. Inevitably, this leads to fragile integrations."
    );
  }

  const transformers = transformersRegistry.get(normalizedTransformerName);

  if (!transformers) {
    return defaultValue;
  }

  const mutable = opts?.mutable; // flag indicating if the value should be mutated instead of returned
  let newValue = defaultValue;

  const transformerPoolSize = transformers.length;
  for (let i = 0; i < transformerPoolSize; i++) {
    const valueCallback = transformers[i];

    try {
      const value = valueCallback({ value: newValue, context });

      if (!mutable) {
        newValue = value;
      }
    } catch (error) {
      document.dispatchEvent(
        new CustomEvent("discourse-error", {
          detail: { messageKey: "broken_transformer_alert", error },
        })
      );

      if (isTesting() && !skipApplyExceptionOnTests) {
        throw error;
      }
    }
  }

  return newValue;
}
```

**File:** frontend/discourse/app/app.js (L197-268)
```javascript
function loadInitializers(app) {
  let initializers = [];
  let instanceInitializers = [];

  let discourseInitializers = [];
  let discourseInstanceInitializers = [];

  for (let moduleName of Object.keys(requirejs.entries)) {
    if (moduleName.startsWith("discourse/") && !moduleName.endsWith("-test")) {
      // In discourse core, initializers follow standard Ember conventions
      if (moduleName.startsWith("discourse/initializers/")) {
        initializers.push(moduleName);
      } else if (moduleName.startsWith("discourse/instance-initializers/")) {
        instanceInitializers.push(moduleName);
      } else {
        // https://meta.discourse.org/t/updating-our-initializer-naming-patterns/241919
        //
        // For historical reasons, the naming conventions in plugins and themes
        // differs from Ember:
        //
        // | Ember                 | Discourse          |                        |
        // | initializers          | pre-initializers   | runs once per app load |
        // | instance-initializers | (api-)initializers | runs once per app boot |
        //
        // In addition, the arguments to the initialize function is different –
        // Ember initializers get either the `Application` or `ApplicationInstance`
        // as the only argument, but the "discourse style" gets an extra container
        // argument preceding that.

        const themeId = moduleThemeId(moduleName);

        if (
          themeId !== undefined ||
          moduleName.startsWith("discourse/plugins/")
        ) {
          if (moduleName.includes("/pre-initializers/")) {
            discourseInitializers.push([moduleName, themeId]);
          } else if (
            moduleName.includes("/initializers/") ||
            moduleName.includes("/api-initializers/")
          ) {
            discourseInstanceInitializers.push([moduleName, themeId]);
          }
        }
      }
    }
  }

  for (let moduleName of initializers) {
    app.initializer(resolveInitializer(moduleName));
  }

  for (let moduleName of instanceInitializers) {
    app.instanceInitializer(resolveInitializer(moduleName));
  }

  for (let [moduleName, themeId] of discourseInitializers) {
    app.initializer(resolveDiscourseInitializer(moduleName, themeId));
  }

  for (let [moduleName, themeId] of discourseInstanceInitializers) {
    app.instanceInitializer(resolveDiscourseInitializer(moduleName, themeId));
  }

  // Plugins that are registered via `<script>` tags.
  for (let [i, callback] of _pluginCallbacks.entries()) {
    app.instanceInitializer({
      name: `_discourse_plugin_${i}`,
      after: "inject-objects",
      initialize: () => withPluginApi(callback.version, callback.code),
    });
  }
```
