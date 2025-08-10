import { defineConfig } from "vite";
import ViteRails from "vite-plugin-rails";
import tailwindcss from "@tailwindcss/vite";
import react from '@vitejs/plugin-react'
import vue from '@vitejs/plugin-vue'
import vueJsx from '@vitejs/plugin-vue-jsx'
import { resolve } from 'path'
import { vite as vidstack } from 'vidstack/plugins';



export default defineConfig({
  server: {
    hmr: true,
  },
  plugins: [
    tailwindcss(),
    vue({
      template: {
        compilerOptions: {
          isCustomElement: (tag) => tag.startsWith('media-'),
        }
      }
    }),
    vueJsx(),
    ViteRails({
      envOptions: { defineOn: "import.meta.env" },
      fullReload: {
        additionalPaths: ["config/routes.rb", "app/views/**/*"],
        delay: 300,
      },
    }),
    vidstack(),
    //react(),
  ],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'app/frontend/webclient'),
      "@plugins": resolve(__dirname, 'plugins'),
    },
  }
});