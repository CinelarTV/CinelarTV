/*
  MonacoTools — helpers for vue-monaco-editor.

  addTypes() registers the PluginAPI type definitions inside Monaco so that
  the code settings (custom_js, etc.) get IntelliSense for window.PluginAPI.

  The original implementation used Webpack's synchronous `require()` and
  `raw-loader`, which are incompatible with Vite. This version uses:
    - `import(..., { assert: { type: 'raw' } })` — not yet widely supported
    - Vite's `?raw` suffix for static asset imports as strings  ✓
    - Dynamic `import()` for the .d.ts content read at build time         ✓
*/

// Vite resolves these at build time and inlines the file contents as strings.
import pluginApiDts  from '../../types/plugin-api.d.ts?raw';
import pluginApiImpl from '../../lib/PluginAPI.ts?raw';

class MonacoTools {
    constructor() {
        throw new Error('This class should not be instantiated');
    }

    static get monaco() {
        return (window as any).monaco;
    }

    static get editor() {
        return (window as any).monaco.editor;
    }

    static get languages() {
        return (window as any).monaco.languages;
    }

    /**
     * Registers PluginAPI type definitions in Monaco's TypeScript worker so that
     * `window.PluginAPI` has full IntelliSense in code-type settings.
     *
     * Called via the `@mount` event of vue-monaco-editor:
     *   <vue-monaco-editor @mount="MonacoTools.addTypes" />
     */
    public static addTypes() {
        const monaco = (window as any).monaco;
        if (!monaco) {
            console.warn('[MonacoTools] Monaco Editor is not loaded yet.');
            return;
        }

        try {
            const ts = monaco.languages.typescript;

            ts.typescriptDefaults.addExtraLib(pluginApiDts,  'plugin-api.d.ts');
            ts.typescriptDefaults.addExtraLib(pluginApiImpl, 'file:///plugin-api.d.ts');
            ts.javascriptDefaults.addExtraLib(pluginApiDts,  'plugin-api.d.ts');
            ts.javascriptDefaults.addExtraLib(pluginApiImpl, 'file:///plugin-api.d.ts');

            console.debug('[MonacoTools] PluginAPI types registered.');
        } catch (e) {
            console.error('[MonacoTools] Failed to register types:', e);
        }
    }
}

export default MonacoTools;
