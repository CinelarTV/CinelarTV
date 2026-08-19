import { resolve } from "path";

export const sharedAlias = {
  "@": resolve(__dirname, "app/frontend/webclient"),
  "@plugins": resolve(__dirname, "plugins"),
  "@cinelartv/core": resolve(__dirname, "packages/core/index.ts"),
  "@cinelartv/plugin-api": resolve(__dirname, "packages/plugin-api/index.ts"),
  "@cinelartv/ui": resolve(__dirname, "packages/ui/index.ts"),
  "@cinelartv/services": resolve(__dirname, "packages/services/index.ts"),
};
