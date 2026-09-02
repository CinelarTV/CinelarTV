import { useSiteSettings } from "../app/services/site-settings";
import { useIconsStore } from "../store/icons";
import { PiniaStore } from "../app/lib/Pinia";

const { siteSettings } = useSiteSettings(PiniaStore);

const PLAYER_ICONS = new Set(["play", "pause", "maximize", "minimize", "volume2", "volumeX"]);

const BASE_ICONS = new Set([
    "activity", "award", "airplay", "arrowRightLeft", "arrowRight", "arrowLeft", "box", "check",
    "copy", "checkCircle", "chevronDown", "chevronLeft", "chevronRight",
    "chevronUp", "clapperboard", "creditCard", "gripVertical", "helpCircle", "info",
    "calendar", "clock", "lock",
    "loader", "logOut", "pause", "maximize", "minimize", "play", "frown", "fastForward",
    "playCircle", "playSquare", "plus", "rotateCcw", "rotateCw", "search", "settings",
    "shieldQuestion", "sparkles", "thumbsUp", "thumbsDown", "user", "wrench", "x", "hardDrive",
    "circleDollarSign", "brush", "testTube2", "telescope", "code2", "cpu", "star", "satelliteDish",
    "rocket", "trash2", "pencil", "layoutGrid", "bookmark", "volume1", "volume2",
    "volumeX", "home", "packageOpen", "webhook", "cast", "shrink", "messageCircleMore",
    "messageCircleOff", "mail", "shield-check", "shuffle", "languages",
    "eye", "save", "send", "bold", "italic", "strikethrough",
    "heading-1", "heading-2", "heading-3",
    "list", "list-ordered", "quote", "code", "minus", "link",
    "undo", "redo", "braces", "monitor", "smartphone",
    "mail-check", "key-round", "unlock", "users"
]);

export const BASE_ICONS_LIST = Array.from(BASE_ICONS);

const toPascalCase = (str: string): string =>
    str.replace(/(^|_|-|\s)([a-z])/g, (_, __, l) => l.toUpperCase()).replace(/[-_\s]/g, "");

const toKebabCase = (str: string): string =>
    str.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();

let iconsModule: Record<string, string> | null = null;

const loadIconsModule = async (): Promise<Record<string, string>> => {
    if (!iconsModule) {
        const mod = await import("lucide-static");
        iconsModule = mod as unknown as Record<string, string>;
    }
    return iconsModule;
};

// ─── Server-side sprite detection (inline) ──────────────────────────────────

let serverSpriteDetected = false;

const detectInlineSprite = (): boolean => {
    if (serverSpriteDetected) return true;

    const iconSheet = document.getElementById("cinelar-icon-sheet");
    if (!iconSheet) return false;

    const symbols = iconSheet.querySelectorAll("symbol");
    if (symbols.length > 0) {
        serverSpriteDetected = true;
        console.log(`[IconLibrary] Inline server sprite detected (${symbols.length} symbols)`);
        return true;
    }

    return false;
};

const getSpriteIconNames = (): string[] => {
    const iconSheet = document.getElementById("cinelar-icon-sheet");
    if (!iconSheet) return [];

    const symbols = iconSheet.querySelectorAll("symbol[id]");
    return Array.from(symbols)
        .map((s) => s.getAttribute("id")!)
        .filter((id) => id && !id.startsWith("vjs-icon-"));
};

// ─── Client-side sprite generation (fallback) ───────────────────────────────

const symbolCache = new Map<string, string[]>();

const createIconSymbol = (iconName: string, icons: Record<string, string>): string[] => {
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

let cachedSpriteKey: string | null = null;
let cachedSpriteContent: string | null = null;

const generateClientSpriteSheet = async (): Promise<boolean> => {
    try {
        const iconSheet = document.getElementById("cinelar-icon-sheet");
        if (!iconSheet) {
            console.error("[IconLibrary] Element 'cinelar-icon-sheet' not found");
            return false;
        }

        const icons = await loadIconsModule();
        const allIcons = getAllIcons();
        const spriteKey = [...allIcons].join(",");

        if (cachedSpriteContent && spriteKey === cachedSpriteKey) {
            iconSheet.innerHTML = cachedSpriteContent;
            return true;
        }

        const svgSymbols: string[] = [];
        for (const iconName of allIcons) {
            svgSymbols.push(...createIconSymbol(iconName, icons));
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

// ─── Public API ─────────────────────────────────────────────────────────────

let iconsStore: ReturnType<typeof useIconsStore> | null = null;

export const getAllIcons = (): Set<string> => {
    if (serverSpriteDetected) {
        return new Set(getSpriteIconNames());
    }

    const iconSet = new Set(BASE_ICONS);

    siteSettings.additional_icons
        ?.split("|")
        .forEach((icon: string) => icon.trim() && iconSet.add(icon.trim()));

    iconsStore ??= useIconsStore();
    iconsStore.icons.forEach((icon: string) => iconSet.add(icon));

    return iconSet;
};

export const generateSpriteSheet = async (): Promise<boolean> => {
    if (detectInlineSprite()) return true;
    return generateClientSpriteSheet();
};

export const clearIconCache = (): void => {
    cachedSpriteContent = null;
    cachedSpriteKey = null;
    symbolCache.clear();
};

export const isIconAvailable = (iconName: string): boolean => {
    if (detectInlineSprite()) {
        const iconSheet = document.getElementById("cinelar-icon-sheet");
        return !!iconSheet?.querySelector(`symbol[id="${iconName}"]`);
    }
    return getAllIcons().has(iconName);
};

const iconLibrary = {
    install: (app: any) => {
        if ((window as any)._cinelarIconSheetInitialized) return;
        (window as any)._cinelarIconSheetInitialized = true;

        detectInlineSprite();

        app.config.globalProperties.$iconLibrary = {
            generateSpriteSheet,
            clearIconCache,
            isIconAvailable,
            getAllIcons,
        };
    },
};

export default iconLibrary;
