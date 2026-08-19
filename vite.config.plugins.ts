import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import vueJsx from "@vitejs/plugin-vue-jsx";
import { resolve } from "path";
import { readFileSync } from "fs";
import { sharedAlias } from "./vite.config.shared";

const pluginDir = process.env.PLUGIN_DIR;
if (!pluginDir) {
  console.error("PLUGIN_DIR environment variable is required");
  process.exit(1);
}

const pluginJsonPath = resolve(pluginDir, "plugin.json");
type PluginManifest = {
  id?: string;
  name?: string;
  version: string;
  entry?: string;
  externals?: string[];
  dependencies?: Record<string, string>;
  frontend?: { entry?: string; externals?: string[] };
};

let pluginJson: PluginManifest;

try {
  pluginJson = JSON.parse(readFileSync(pluginJsonPath, "utf-8"));
} catch {
  console.error(`Cannot read ${pluginJsonPath}`);
  process.exit(1);
}

const pluginName = pluginJson.id || pluginJson.name;
if (!pluginName) {
  console.error("plugin.json requires id (or legacy name)");
  process.exit(1);
}
const entryFile = pluginJson.frontend?.entry || pluginJson.entry || "app/index.ts";
const entryPath = resolve(pluginDir, entryFile);

// Plugins declare exactly which public core modules they need. `externals` is
// now real build input; legacy top-level externals remains supported. Runtime
// singleton specifiers are allowed only when explicitly requested.
const declaredExternals = new Set([
  ...Object.keys(pluginJson.dependencies || {}).filter((name) => name.startsWith("@cinelartv/")),
  ...(pluginJson.frontend?.externals || pluginJson.externals || []),
]);
const allowedExternals = new Set(
  (process.env.CINELARTV_PUBLIC_PACKAGES || "@cinelartv/ui,@cinelartv/core,@cinelartv/plugin-api,vue,pinia,vue-router")
    .split(",")
    .filter(Boolean),
);
const externals = [...declaredExternals].filter((name) => allowedExternals.has(name));
const unsupportedExternals = [...declaredExternals].filter((name) => !allowedExternals.has(name));
if (unsupportedExternals.length > 0) {
  console.error(`Plugin declares non-public externals: ${unsupportedExternals.join(", ")}`);
  process.exit(1);
}

export default defineConfig({
  mode: "production",
  define: {
    "process.env": {},
  },
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
      external: externals,
      output: {
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
    alias: sharedAlias,
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
