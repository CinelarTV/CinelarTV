import { defineConfig } from "vite";
import ViteRails from "vite-plugin-rails";
import tailwindcss from "@tailwindcss/vite";
//import react from '@vitejs/plugin-react'
import vue from '@vitejs/plugin-vue'
import vueJsx from '@vitejs/plugin-vue-jsx'
import { resolve } from 'path'




export default defineConfig({
  server: {
    hmr: {
      host: 'localhost',
      port: 3036,
      protocol: 'ws'
    },
    port: 3036
  },
  build: {
    target: "esnext",
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router', 'pinia'],
          ui: ['@headlessui/vue', 'vue-final-modal', 'vue3-toastify'],
          media: ['shaka-player'],
          editor: ['@guolao/vue-monaco-editor', 'monaco-editor'],
          charts: ['chart.js'],
          utils: ['axios', 'i18n-js']
        },
        chunkFileNames: (chunkInfo) => {
          if (chunkInfo.name === 'vendor') return 'assets/vendor.[hash].js';
          if (chunkInfo.name === 'ui') return 'assets/ui.[hash].js';
          if (chunkInfo.name === 'media') return 'assets/media.[hash].js';
          if (chunkInfo.name === 'editor') return 'assets/editor.[hash].js';
          if (chunkInfo.name === 'charts') return 'assets/charts.[hash].js';
          if (chunkInfo.name === 'utils') return 'assets/utils.[hash].js';
          return 'assets/[name].[hash].js';
        }
      }
    },
    chunkSizeWarningLimit: 1000
  },
  plugins: [
    tailwindcss(),
    vue({
      template: {
        compilerOptions: {
          isCustomElement: (tag) => false,
        }
      }
    }),
    vueJsx({
      isCustomElement: (tag) => false,
    }),
    ViteRails({
      envOptions: { defineOn: "import.meta.env" },
      fullReload: {
        additionalPaths: ["config/routes.rb", "app/views/**/*"],
        delay: 300,
      },
    }),
    //react(),
  ],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'app/frontend/webclient'),
      "@plugins": resolve(__dirname, 'plugins'),
    },
  },
  optimizeDeps: {
    include: [
      'vue',
      'vue-router',
      'pinia',
      'axios',
      'i18n-js',
      'shaka-player'
    ]
  }
});