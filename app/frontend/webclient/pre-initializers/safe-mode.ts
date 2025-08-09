import { query } from "@/utils/query";

const safeModeRaw = query.safe_mode;
const safeModeOptions = safeModeRaw ? safeModeRaw.split(",") : [];
const hasSafeMode = !!safeModeRaw;
const noPlugins = safeModeOptions.includes("no_plugins");
const noTheme = safeModeOptions.includes("no_theme");

if (hasSafeMode) {
    document.body.classList.add("safe-mode");

    if (noPlugins) {
        console.warn("Safe mode enabled. Plugins will not be loaded.");
    }

    if (noTheme) {
        console.warn("Safe mode enabled. Custom personalization will not be loaded.");
        const theming = document.getElementById("app-theming-custom");
        if (theming) theming.remove();
    }
}

export const SafeMode = {
    enabled: hasSafeMode,
    options: safeModeOptions,
    noTheme,
    noPlugins,
};