import * as icons from "lucide-static";
import { SiteSettings } from "../pre-initializers/essentials-preload"; // Inject is not available before App initialization, so we need to import it here

const ICON_MAP = [
    "activity",
    "airplay",
    "wrench",
    "loader",
    "playCircle",
    "plus",
    "info",
    "thumbsUp",
    "chevronLeft",
    "play",
    "chevronRight",
    "chevronDown",
    "chevronUp",
    "search",
    "x",
    "check",
    "checkCircle",
    "pause",
    "rotateCw",
    "rotateCcw",
    "gripVertical",
];



const toLowerCamelCase = (str) => {
    return str.replace(/_([a-z])/g, (match, letter) => {
        return letter.toUpperCase();
    });
};

const generateSpriteSheet = () => {
    let iconCount = 0;
    if (SiteSettings?.additional_icons) {
        SiteSettings.additional_icons.split('|').forEach((icon) => {
            ICON_MAP.push(icon);
        });
    }

    const svgSymbols = ICON_MAP.map((icon) => {
        const lowerCamelCaseIcon = toLowerCamelCase(icon);
        const dashCaseIcon = lowerCamelCaseIcon.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();
        const symbol = icons[icon];
        if (!symbol) {
            console.warn(`[Icon Library] Icon ${icon} not found. Skipping...`);
            delete ICON_MAP[icon];
            return "";
        }
        iconCount++;
        return `<symbol id="${dashCaseIcon}" viewBox="0 0 24 24">${symbol}</symbol>`;
    });

    const svgSpriteContent = `<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">${svgSymbols.join("")}</svg>`;

    // Inyecta el contenido en la etiqueta con id "cinelar-icon-sheet"

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
