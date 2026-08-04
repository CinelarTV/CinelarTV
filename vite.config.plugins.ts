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
let pluginJson: { name: string; version: string; entry?: string };

try {
  pluginJson = JSON.parse(readFileSync(pluginJsonPath, "utf-8"));
} catch {
  console.error(`Cannot read ${pluginJsonPath}`);
  process.exit(1);
}

const pluginName = pluginJson.name;
const entryFile = pluginJson.entry || "app/index.ts";
const entryPath = resolve(pluginDir, entryFile);

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
      external: ["vue", "pinia", "vue-router", "axios"],
      output: {
        assetFileNames: (assetInfo) => {
          if (assetInfo.name?.endsWith(".css")) return "style.[hash].css";
          return "assets/[name].[hash][extname]";
        },
        globals: {
          vue: "Vue",
          pinia: "Pinia",
          "vue-router": "VueRouter",
          axios: "axios",
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
