// Lista de nombres válidos de plugin outlets
export const PLUGIN_OUTLET_NAMES = [
    'home:before-carousel',
    'home:after-carousel',
    'footer:before',
    'footer:after',
    "player:top-controls:right",
    "player:after-media-player"
    // Agrega aquí todos los outlets que quieras soportar
] as const;

export type PluginOutletName = typeof PLUGIN_OUTLET_NAMES[number];
