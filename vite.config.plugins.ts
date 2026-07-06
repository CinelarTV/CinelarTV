import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import vueJsx from "@vitejs/plugin-vue-jsx";
import { resolve, basename } from "path";
import { readFileSync } from "fs";

/**
 * Vite config for building individual third-party CinelarTV plugins.
 *
 * Usage:
 *   PLUGIN_DIR=/path/to/plugins/my-plugin npx vite build --config vite.config.plugins.ts
 *
 * The plugin must have a plugin.json with at least { name, version, entry }.
 * Core dependencies (vue, pinia, @/*) are externalized and provided by the host at runtime.
 */

const pluginDir = process.env.PLUGIN_DIR;
if (!pluginDir) {
  console.error("PLUGIN_DIR environment variable is required");
  process.exit(1);
}

const pluginJsonPath = resolve(pluginDir, "plugin.json");
let pluginJson: { name: string; version: string; entry?: string; externals?: string[] };

try {
  pluginJson = JSON.parse(readFileSync(pluginJsonPath, "utf-8"));
} catch {
  console.error(`Cannot read ${pluginJsonPath}`);
  process.exit(1);
}

const pluginName = pluginJson.name;
const entryFile = pluginJson.entry || "app/index.ts";
const entryPath = resolve(pluginDir, entryFile);

// Core modules that plugins can import from the host app.
// These are mapped to window.CinelarTV.* at runtime.
const coreExternals: Record<string, string> = {
  vue: "CinelarTV.Vue",
  "vue-router": "CinelarTV.VueRouter",
  pinia: "CinelarTV.Pinia",
  axios: "CinelarTV.axios",
  // Core CinelarTV modules — mapped via the @/ alias
  "@/lib/plugin-events": "CinelarTV.PluginEvents",
  "@/app/services/site-settings": "CinelarTV.SiteSettings",
  "@/components/PluginOutlet": "CinelarTV.PluginOutlet",
  "@/stores/pluginOutlets": "CinelarTV.PluginOutlets",
};

// Plugin-declared externals override defaults
const externals = { ...coreExternals };
if (pluginJson.externals) {
  for (const ext of pluginJson.externals) {
    if (!externals[ext]) {
      externals[ext] = `CinelarTV.libs.${ext}`;
    }
  }
}

export default defineConfig({
  mode: "production",
  publicDir: false,
  build: {
    target: "esnext",
    lib: {
      entry: entryPath,
      formats: ["es"],
      fileName: () => "index.[hash].js",
    },
    outDir: resolve("public", "plugins", pluginName),
    emptyOutDir: true,
    rollupOptions: {
      external: Object.keys(externals),
      output: {
        globals: externals,
        assetFileNames: (assetInfo) => {
          if (assetInfo.name?.endsWith(".css")) return "style.[hash].css";
          return "assets/[name].[hash][extname]";
        },
      },
    },
    cssCodeSplit: false,
    sourcemap: false,
    minify: true,
  },
  resolve: {
    alias: {
      "@": resolve(__dirname, "app/frontend/webclient"),
      "@plugins": resolve(__dirname, "plugins"),
    },
  },
  plugins: [
    vue({
      template: {
        compilerOptions: {
          isCustomElement: (tag) => false,
        },
      },
    }),
    vueJsx({
      isCustomElement: (tag) => false,
    }),
  ],
});
