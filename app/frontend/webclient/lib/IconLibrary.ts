import * as icons from "lucide-static";
import { useSiteSettings } from "../app/services/site-settings";
import { useIconsStore } from "../store/icons";
import { PiniaStore } from "../app/lib/Pinia";

const { siteSettings } = useSiteSettings(PiniaStore);

const PLAYER_ICONS = new Set(["play", "pause", "maximize", "minimize", "volume2", "volumeX"]);

const BASE_ICONS = new Set([
    "activity", "award", "airplay", "arrowRightLeft", "arrowRight", "box", "check",
    "copy", "checkCircle", "chevronDown", "chevronLeft", "chevronRight",
    "chevronUp", "clapperboard", "creditCard", "gripVertical", "helpCircle", "info",
    "calendar", "clock", "lock",
    "loader", "logOut", "pause", "maximize", "minimize", "play", "frown", "fastForward",
    "playCircle", "playSquare", "plus", "rotateCcw", "rotateCw", "search", "settings",
    "shieldQuestion", "sparkles", "thumbsUp", "user", "wrench", "x", "hardDrive",
    "circleDollarSign", "brush", "testTube2", "telescope", "code2", "cpu", "star", "satelliteDish",
    "rocket", "trash2", "pencil", "layoutGrid", "bookmark", "volume1", "volume2",
    "volumeX", "home", "packageOpen", "webhook", "cast", "shrink", "messageCircleMore",
    "messageCircleOff", "mail", "shield-check", "shuffle"
]);

const toKebabCase = (str: string): string =>
    str.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();

const toPascalCase = (str: string): string =>
    str.replace(/(^|_|-|\s)([a-z])/g, (_, __, l) => l.toUpperCase()).replace(/[-_\s]/g, "");

// Cache por icono individual
const symbolCache = new Map<string, string[]>();

const createIconSymbol = (iconName: string): string[] => {
    if (symbolCache.has(iconName)) return symbolCache.get(iconName)!;

    const pascalName = toPascalCase(iconName);
    const symbol = icons[pascalName];

    if (!symbol) {
        console.warn(`[IconLibrary] Icon "${iconName}" (as ${pascalName}) not found. Omitting...`);
        symbolCache.set(iconName, []);
        return [];
    }

    const kebabName = toKebabCase(pascalName);
    const result = [`<symbol id="${kebabName}" viewBox="0 0 24 24">${symbol}</symbol>`];

    if (PLAYER_ICONS.has(iconName)) {
        result.push(`<symbol id="vjs-icon-${kebabName}" viewBox="0 0 24 24">${symbol}</symbol>`);
    }

    symbolCache.set(iconName, result);
    return result;
};

// Instancia única del store
let iconsStore: ReturnType<typeof useIconsStore> | null = null;

const getAllIcons = (): Set<string> => {
    const iconSet = new Set(BASE_ICONS);

    siteSettings.additional_icons
        ?.split("|")
        .forEach((icon: string) => icon.trim() && iconSet.add(icon.trim()));

    iconsStore ??= useIconsStore();
    iconsStore.icons.forEach((icon: string) => iconSet.add(icon));

    return iconSet;
};

let cachedSpriteKey: string | null = null;
let cachedSpriteContent: string | null = null;

export const generateSpriteSheet = (): boolean => {
    try {
        const iconSheet = document.getElementById("cinelar-icon-sheet");
        if (!iconSheet) {
            console.error("[IconLibrary] Element 'cinelar-icon-sheet' not found");
            return false;
        }

        const allIcons = getAllIcons();
        const spriteKey = [...allIcons].join(",");

        if (cachedSpriteContent && spriteKey === cachedSpriteKey) {
            iconSheet.innerHTML = cachedSpriteContent;
            return true;
        }

        const svgSymbols: string[] = [];
        for (const iconName of allIcons) {
            svgSymbols.push(...createIconSymbol(iconName));
        }

        cachedSpriteContent = `<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">${svgSymbols.join("")}</svg>`;
        cachedSpriteKey = spriteKey;
        iconSheet.innerHTML = cachedSpriteContent;

        console.log(`[IconLibrary] Loaded ${allIcons.size} icons (${svgSymbols.length} symbols)`);
        return true;

    } catch (error) {
        console.error("[IconLibrary] Error generating sprite sheet:", error);
        return false;
    }
};

export const clearIconCache = (): void => {
    cachedSpriteContent = null;
    cachedSpriteKey = null;
    symbolCache.clear();
};

export const isIconAvailable = (iconName: string): boolean =>
    toPascalCase(iconName) in icons;

const iconLibrary = {
    install: (app: any) => {
        if ((window as any)._cinelarIconSheetInitialized) return;
        (window as any)._cinelarIconSheetInitialized = true;

        const raf = window.requestAnimationFrame ?? setTimeout;
        raf(() => generateSpriteSheet());

        app.config.globalProperties.$iconLibrary = {
            generateSpriteSheet,
            clearIconCache,
            isIconAvailable,
            getAllIcons,
        };
    },
};

export default iconLibrary;