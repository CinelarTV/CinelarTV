import { resolve } from "path";

export const sharedAlias = {
  "@": resolve(__dirname, "app/frontend/webclient"),
  "@plugins": resolve(__dirname, "plugins"),
};
