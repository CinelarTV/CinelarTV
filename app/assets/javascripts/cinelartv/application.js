import { createApp } from 'vue/dist/vue.esm-bundler'
import App from './App.vue'
import EssentialsPreloaded from './pre-initializers/essentials-preload';
import AppRouter from './routes/router-map';
import { createHead  } from 'unhead'
import twemoji from './plugins/twemoji'
const metaManager = createHead()
import Logster from './lib/logster'
import globalComponents from './lib/global-components';
import I18n from './lib/i18n'
import ColorPicker from './plugins/color-picker'
import * as ConfirmDialog from 'vuejs-confirm-dialog'
import Vue3Toasity from 'vue3-toastify';
import { createPinia } from 'pinia'
import Vue3Progress from "vue3-progress";
import Axios from './lib/axios-setup'
import { addCompiledComponent } from './lib/componentManager';
require('./lib/message-bus')
import 'vue3-toastify/dist/index.css';
import iconLibrary from './lib/icon-library';


const CinelarTV = createApp(App)
const pinia = createPinia()

CinelarTV.addComponent = addCompiledComponent



let pluginMap = [
    EssentialsPreloaded,
    AppRouter,
    metaManager,
    globalComponents,
    twemoji,
    Logster,
    I18n,
    ColorPicker,
    ConfirmDialog,
    pinia,
    Axios,
    iconLibrary
]

CinelarTV.use(Vue3Progress, {
    color: 'var(--c-tertiary-color)',
    height: '4px'
})

CinelarTV.use(Vue3Toasity, {
    duration: 5000,
    position: 'bottom-center',
})

pluginMap.map(plugin => {
    CinelarTV.use(plugin)
})

/* Remove noscript tag on load */

document.querySelector("noscript")?.remove();

MessageBus.start();


export default CinelarTV