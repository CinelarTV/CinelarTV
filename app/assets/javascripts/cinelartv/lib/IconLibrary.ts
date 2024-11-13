import * as icons from "lucide-static";
import { useSiteSettings } from "../app/services/site-settings";
import { useIconsStore } from "../store/icons";
import { PiniaStore } from "../app/lib/Pinia";

const { siteSettings } = useSiteSettings(PiniaStore);

const PLAYER_ICONS = ["play", "pause", "maximize", "minimize"]
const ICON_MAP = [
    "activity",
    "award",
    "airplay",
    "arrowRightLeft",
    "arrowRight",
    "box",
    "check",
    "checkCircle",
    "chevronDown",
    "chevronLeft",
    "chevronRight",
    "chevronUp",
    "clapperboard",
    "creditCard",
    "gripVertical",
    "helpCircle",
    "info",
    "loader",
    "logOut",
    "pause",
    "maximize",
    "minimize",
    "play",
    "frown",
    "fastForward",
    "playCircle",
    "playSquare",
    "plus",
    "rotateCcw",
    "rotateCw",
    "search",
    "settings",
    "shieldQuestion",
    "sparkles",
    "thumbsUp",
    "user",
    "wrench",
    "x",
    "hardDrive",
    "circleDollarSign",
    "brush",
    "testTube2",
    "code2",
    "cpu",
    "rocket",
    "trash2",
    "pencil",
    "layoutGrid",
];





const toLowerCamelCase = (str) => {
    return str.replace(/_([a-z])/g, (match, letter) => {
        return letter.toUpperCase();
    });
};

export const generateSpriteSheet = () => {
    let iconCount = 0;
    const iconsStore = useIconsStore(); // Obtiene el store de íconos

    if (siteSettings.value?.additional_icons) {
        siteSettings.value.additional_icons.split('|').forEach((icon) => {
            ICON_MAP.push(icon);
        });
    }

    iconsStore.icons.forEach((icon) => {
        ICON_MAP.push(icon);
    });

    let svgSymbols = [];

    ICON_MAP.map((icon) => {
        const lowerCamelCaseIcon = toLowerCamelCase(icon);
        const dashCaseIcon = lowerCamelCaseIcon.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();
        const symbol = icons[icon];
        if (!symbol) {
            console.warn(`[Icon Library] Icon ${icon} not found. Skipping...`);
            delete ICON_MAP[icon];
            return "";
        }
        iconCount++;

        if (PLAYER_ICONS.includes(icon)) {
            // Add additional symbol with "vjs-icon" prefix
            svgSymbols.push(`<symbol id="vjs-icon-${dashCaseIcon}" viewBox="0 0 24 24">${symbol}</symbol>`);
        }

        svgSymbols.push(`<symbol id="${dashCaseIcon}" viewBox="0 0 24 24">${symbol}</symbol>`);
    });

    const svgSpriteContent = `<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">${svgSymbols.join("")}</svg>`;

    // Inyecta el contenido en la etiqueta con id "cinelar-icon-sheet" (Primero la crea si no existe)

    const iconSheet = document.getElementById("cinelar-icon-sheet");
    if (iconSheet) {
        iconSheet.innerHTML = svgSpriteContent;
        console.log(`[Icon Library] ${iconCount} icons loaded`);
    } else {
        console.error("[Icon Library] Icon sheet not found");
    }
};

const iconLibrary = {
    install: (app) => {
        generateSpriteSheet(); // Genera el sprite antes de registrar los íconos
    },
};

export default iconLibrary;
