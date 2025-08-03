//import User from "../app/models/User.js";
import { green } from "console-log-colors";
import { create } from "zustand";

// Tipos
interface PreloadedData {
  currentUser: any; // Puedes tipar mejor según tu modelo
  SiteSettings: any;
  isMobile: boolean;
  homepageData: any;
}

export const showPreloaderError = (error?: Error): void => {
  // Elimina splash si existe
  const splashElement = document.getElementById("c-splash");
  if (splashElement) splashElement.remove();

  // Construcción del contenedor de error
  const errorDiv = document.createElement("div");
  errorDiv.id = "preload-failed";
  errorDiv.innerHTML = `
    <h1>Oops! Something went wrong</h1>
    <pre>${error?.stack || error?.message || ""}</pre>
    <button class="reload-btn">Reload</button>
  `;

  // Asigna el evento al botón
  const reloadButton = errorDiv.querySelector("button")!;
  reloadButton.onclick = () => window.location.reload();

  document.body.appendChild(errorDiv);
};

let preloaded: PreloadedData;
const preloadedDataElement = document.getElementById("data-preloaded");
if (preloadedDataElement) {
  preloaded = JSON.parse(preloadedDataElement.dataset.preloaded || '{}') as PreloadedData;
} else {
  showPreloaderError(new Error("Unable to boot CinelarTV: Essential preloaded data not found"));
  throw new Error(`Unable to boot CinelarTV: Essential preloaded data not found`);
}

// Zustand store
export const usePreloadedStore = create<PreloadedData>(() => ({
  currentUser: preloaded.currentUser,
  SiteSettings: preloaded.SiteSettings,
  isMobile: preloaded.isMobile,
  homepageData: preloaded.homepageData,
}));

export const isMobile = preloaded.isMobile;

export const Language = {
  current: preloaded.currentUser?.locale || preloaded.SiteSettings?.default_locale,
  default: preloaded.SiteSettings?.default_locale,
};