import { ref } from "vue";
export const showPreloaderError = () => {
    document.getElementById("c-splash").remove()
    const errorDiv = document.createElement("div");
    errorDiv.setAttribute("id", "preload-failed")
    const errorText = document.createTextNode("Unable to boot CinelarTV: Essential preloaded data not found");
    errorDiv.appendChild(errorText)
    document.body.appendChild(errorDiv)
}
  
  let preloaded;
  const preloadedDataElement = document.getElementById("data-preloaded");
  
  if (preloadedDataElement) {
    preloaded = JSON.parse(preloadedDataElement.dataset.preloaded);
  }
  else {
    showPreloaderError()
    throw "Unable to boot CinelarTV: Essential preloaded data not found";
  }
  
  let preloadedData = {
    currentUser: preloaded.currentUser,
    SiteSettings: preloaded.SiteSettings,
    isMobile: preloaded.isMobile,
  };

  const homepageData = ref(null) // We need to use ref here because we need to be able to change the value of this variable later

  if (preloaded.homepageData) {
    homepageData.value = preloaded.homepageData
  }

    
  
  
  export default {
    install: (app) => {
      Object.assign(app.config.globalProperties, preloadedData);
      app.provide("currentUser", preloadedData.currentUser);
      app.provide("SiteSettings", preloadedData.SiteSettings);
      app.provide("isMobile", preloadedData.isMobile);
      app.provide("homepageData", homepageData);
    }
  }
  
  export const { SiteSettings, currentUser, isMobile } = preloadedData;

  
  export const Language = {
    current: preloadedData.currentUser?.locale || preloadedData.SiteSettings.default_locale,
    default: preloadedData.SiteSettings.default_locale
  }