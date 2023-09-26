import { query } from "../utils/query";

if (query.safe_mode) {
    document.body.classList.add('safe-mode')
    const safeMode = query.safe_mode.split(',')

    if (safeMode.includes('no_plugins')) {
        console.warn('Safe mode enabled. Plugins will not be loaded.')
    }

    if (safeMode.includes('no_theme')) {
        console.warn('Safe mode enabled. Custom personalization will not be loaded.')
        try {
            document.getElementById('app-theming-custom').remove()
        } catch (error) {
            // Do nothing, maybe the element doesn't exist
        }
    }
}

export const SafeMode = {
    enabled: query.safe_mode,
    options: query.safe_mode?.split(','),
    noTheme: query.safe_mode?.split(',').includes('no_theme'),
    noPlugins: query.safe_mode?.split(',').includes('no_plugins')
}