import { defineConfig } from "vite";
import ViteRails from "vite-plugin-rails";
import tailwindcss from "@tailwindcss/vite";
import react from '@vitejs/plugin-react'


export default defineConfig({
  server: {
    hmr: true,
  },
  plugins: [
    tailwindcss(),
    ViteRails({
      envOptions: { defineOn: "import.meta.env" },
      fullReload: {
        additionalPaths: ["config/routes.rb", "app/views/**/*"],
        delay: 300,
      },
    }),
    react(),
  ],
});