import * as icons from "lucide-static";
import { useSiteSettings } from "../app/services/site-settings";
import { useIconsStore } from "../store/icons";
import { PiniaStore } from "../app/lib/Pinia";

const { siteSettings } = useSiteSettings(PiniaStore);
console.log({ icons })
// Constantes optimizadas
const PLAYER_ICONS = new Set(["play", "pause", "maximize", "minimize", "volume2", "volumeX"]);

const BASE_ICONS = [
    "activity", "award", "airplay", "arrowRightLeft", "arrowRight", "box", "check",
    "checkCircle", "chevronDown", "chevronLeft", "chevronRight", "chevronUp",
    "clapperboard", "creditCard", "gripVertical", "helpCircle", "info", "loader",
    "logOut", "pause", "maximize", "minimize", "play", "frown", "fastForward",
    "playCircle", "playSquare", "plus", "rotateCcw", "rotateCw", "search",
    "settings", "shieldQuestion", "sparkles", "thumbsUp", "user", "wrench", "x",
    "hardDrive", "circleDollarSign", "brush", "testTube2", "code2", "cpu",
    "rocket", "trash2", "pencil", "layoutGrid", "bookmark", "volume1", "volume2", "volumeX",
    "home", "packageOpen", "webhook", "cast", "shrink", "messageCircleMore", "messageCircleOff"
] as const;

// Cache para evitar regenerar el sprite innecesariamente
let cachedSpriteContent: string | null = null;
let lastIconCount = 0;

/**
 * Convierte snake_case a camelCase de forma optimizada
 */
const toCamelCase = (str: string): string => {
    return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
};

/**
 * Convierte camelCase a kebab-case de forma optimizada
 */
const toKebabCase = (str: string): string => {
    return str.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();
};

/**
 * Convierte cualquier nombre de icono a PascalCase
 */
const toPascalCase = (str: string): string => {
    return str
        .replace(/(^|_|-|\s)([a-z])/g, (_, __, letter) => letter.toUpperCase())
        .replace(/_/g, '')
        .replace(/-/g, '');
};

/**
 * Obtiene todos los iconos únicos de diferentes fuentes
 */
const getAllIcons = (): Set<string> => {
    const iconSet = new Set<string>(BASE_ICONS);

    // Agregar iconos adicionales de configuración
    if (siteSettings.additional_icons) {
        siteSettings.additional_icons
            .split('|')
            .filter(Boolean)
            .forEach((icon: string) => iconSet.add(icon.trim()));
    }

    // Agregar iconos del store
    const iconsStore = useIconsStore();
    iconsStore.icons.forEach(icon => iconSet.add(icon));

    return iconSet;
};

/**
 * Crea un símbolo SVG para un icono
 */
const createIconSymbol = (iconName: string): string[] => {
    const pascalCaseIcon = toPascalCase(iconName);
    const kebabCaseIcon = toKebabCase(pascalCaseIcon);
    const symbol = icons[pascalCaseIcon];

    if (!symbol) {
        console.warn(`[IconLibrary] Icon "${iconName}" (as ${pascalCaseIcon}) not fund on lucide-static. Omitting...`);
        return [];
    }

    const symbols: string[] = [];
    const baseSymbol = `<symbol id="${kebabCaseIcon}" viewBox="0 0 24 24">${symbol}</symbol>`;
    symbols.push(baseSymbol);

    // Agregar símbolo adicional para el reproductor de video
    if (PLAYER_ICONS.has(iconName)) {
        symbols.push(`<symbol id="vjs-icon-${kebabCaseIcon}" viewBox="0 0 24 24">${symbol}</symbol>`);
    }

    return symbols;
};

/**
 * Genera el sprite sheet de iconos de forma optimizada
 */
export const generateSpriteSheet = (): boolean => {
    try {
        const iconSheet = document.getElementById("cinelar-icon-sheet");
        if (!iconSheet) {
            console.error("[IconLibrary] Element with id 'cinelar-icon-sheet' not found");
            return false;
        }

        const allIcons = getAllIcons();
        const currentIconCount = allIcons.size;

        // Usar cache si no han cambiado los iconos
        if (cachedSpriteContent && currentIconCount === lastIconCount) {
            iconSheet.innerHTML = cachedSpriteContent;
            return true;
        }

        const svgSymbols: string[] = [];
        let validIconCount = 0;

        // Generar símbolos de forma más eficiente
        for (const iconName of allIcons) {
            const symbols = createIconSymbol(iconName);
            if (symbols.length > 0) {
                svgSymbols.push(...symbols);
                validIconCount++;
            }
        }

        // Crear el contenido del sprite
        const spriteContent = `<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">${svgSymbols.join("")}</svg>`;

        // Actualizar cache y DOM
        cachedSpriteContent = spriteContent;
        lastIconCount = currentIconCount;
        iconSheet.innerHTML = spriteContent;

        console.log(`[IconLibrary] Successfully loaded ${validIconCount} icons (${svgSymbols.length} symbols total)`);
        return true;

    } catch (error) {
        console.error("[IconLibrary] Error generating sprite sheet:", error);
        return false;
    }
};

/**
 * Limpia el cache del sprite sheet
 */
export const clearIconCache = (): void => {
    cachedSpriteContent = null;
    lastIconCount = 0;
};

/**
 * Verifica si un icono está disponible
 */
export const isIconAvailable = (iconName: string): boolean => {
    const pascalCaseIcon = toPascalCase(iconName);
    return pascalCaseIcon in icons;
};

/**
 * Plugin de iconos optimizado para Vue
 */
const iconLibrary = {
    install: (app: any) => {
        // Evitar múltiples inicializaciones
        if ((window as any)._cinelarIconSheetInitialized) return;
        (window as any)._cinelarIconSheetInitialized = true;

        // requestAnimationFrame cross-browser y fallback seguro
        const raf =
            window.requestAnimationFrame ||
            (window as any).webkitRequestAnimationFrame ||
            (window as any).mozRequestAnimationFrame ||
            (window as any).msRequestAnimationFrame;
        if (typeof raf === 'function') {
            raf(() => generateSpriteSheet());
        } else {
            setTimeout(() => generateSpriteSheet(), 0);
        }

        // Exponer utilidades globalmente si es necesario
        app.config.globalProperties.$iconLibrary = {
            generateSpriteSheet,
            clearIconCache,
            isIconAvailable,
            getAllIcons
        };
    },
};

export default iconLibrary;

