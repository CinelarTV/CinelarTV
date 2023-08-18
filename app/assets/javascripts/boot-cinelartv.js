import { showPreloaderError } from './cinelartv/pre-initializers/essentials-preload';

import(/* webpackChunkName: "cinelartv" */ './cinelartv/application').then(module => {
    const CinelarTV = module.default;
    CinelarTV.mount('#cinelartv');
    /* Remove noscript tag on load */
    document.querySelector("noscript")?.remove();
    /* Make CinelarTV available globally */
    window.CinelarTV = CinelarTV;    

}).catch(error => {
    console.log(error);
    showPreloaderError();
    throw "Unable to boot CinelarTV: Essential preloaded data not found";
});
