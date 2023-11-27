import { ref, App } from "vue";
import User from "../app/models/User";
import { useCurrentUser } from "../app/services/current-user";
import { useSiteSettings } from "../app/services/site-settings";
import { PiniaStore } from "../app/lib/Pinia";
import { green } from "console-log-colors"

interface PreloadedData {
  currentUser: User | null;
  SiteSettings: any;
  isMobile: boolean;
  homepageData: any; // Ajusta el tipo según la estructura real
}

export const showPreloaderError = (error?: Error): void => {
  const splashElement = document.getElementById("c-splash");
  if (splashElement) {
    splashElement.remove();
  }

  const errorDiv = document.createElement("div");
  errorDiv.id = "preload-failed";
  let errorTitle = "Oops! Something went wrong";
  let errorBody = document.createTextNode("")
  if (error) {
    errorBody = document.createTextNode(error.stack || error.message);
  }

  let reloadButton = document.createElement("button");
  reloadButton.innerText = "Reload";
  reloadButton.classList.add("bg-white", "font-bold", "py-2", "px-4", "rounded", "focus:outline-none", "focus:shadow-outline", "hover:bg-gray-100", "hover:text-gray-900", "mt-4");
  reloadButton.style.marginTop = "1rem";
  reloadButton.style.color = "#000";
  reloadButton.onclick = () => {
    window.location.reload();
  };

  errorDiv.innerHTML = `<h1>${errorTitle}</h1>`;


  errorDiv.appendChild(errorBody);
  errorDiv.appendChild(reloadButton);

  document.body.appendChild(errorDiv);
};

let preloaded: PreloadedData;

const preloadedDataElement = document.getElementById("data-preloaded");

if (preloadedDataElement) {
  preloaded = JSON.parse(preloadedDataElement.dataset.preloaded) as PreloadedData;
} else {
  showPreloaderError(new Error("Unable to boot CinelarTV: Essential preloaded data not found"));
  throw new Error(`Unable to boot CinelarTV: Essential preloaded data not found`);
}

preloaded.currentUser = preloaded.currentUser ? new User(preloaded.currentUser) : null;

const homepageData = ref(preloaded.homepageData || null); // Utiliza el valor directamente si está definido

const setPreloadedData = () => {
  console.log("Setting preloaded data");
  const { setUser } = useCurrentUser(PiniaStore);
  const { setSiteSettings } = useSiteSettings(PiniaStore);
  setUser(preloaded.currentUser);
  setSiteSettings(preloaded.SiteSettings);
}

setPreloadedData();


const install = (app: App): void => {
  app.use(PiniaStore);
  Object.assign(app.config.globalProperties, preloaded);

  app.provide("currentUser", preloaded.currentUser);
  app.provide("SiteSettings", preloaded.SiteSettings);
  app.provide("isMobile", preloaded.isMobile);
  app.provide("homepageData", homepageData);

  console.log(`${green.bold("[CinelarTV]")} Preloaded data installed`);
};

export default {
  install,
};


export const { isMobile } = preloaded;

export const Language = {
  // @ts-ignore
  current: preloaded.currentUser?.locale || preloaded.SiteSettings.default_locale,
  default: preloaded.SiteSettings["default_locale"],
};
