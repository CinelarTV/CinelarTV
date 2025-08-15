import { createApp } from 'vue'
import App from './App.vue'
import EssentialsPreloaded from './pre-initializers/essentials-preload';
//import PluginComponents from './lib/plugin-components';
import { createHead } from 'unhead'
import twemoji from './plugins/twemoji'
import AppRouter from './routes/router-map';
const metaManager = createHead()
import Logster from './lib/Logster'
import globalComponents from './lib/global-components';
import I18n from './lib/i18n'
import ColorPicker from './plugins/color-picker'
import * as ConfirmDialog from 'vuejs-confirm-dialog'
import Vue3Progress from "vue3-progress";
import VueMobileDetection from "vue-mobile-detection";

import Axios from './lib/Ajax'
//import { addCompiledComponent } from './lib/componentManager';

import 'vue3-toastify/dist/index.css';
import iconLibrary from './lib/IconLibrary';
import { install as VueMonacoEditorPlugin } from '@guolao/vue-monaco-editor'
import { messageBus } from "./lib/MessageBus";


const CinelarTV = createApp(App)


let pluginMap = [
    EssentialsPreloaded,
    metaManager,
    AppRouter,
    globalComponents,
    twemoji,
    Logster,
    I18n,
    ColorPicker,
    ConfirmDialog,
    Axios,
    iconLibrary,
    VueMobileDetection
]

CinelarTV.use(Vue3Progress, {
    color: 'var(--c-tertiary-color)',
    height: '4px'
})


CinelarTV.use(VueMonacoEditorPlugin, {
    paths: {
        vs: 'https://cdn.jsdelivr.net/npm/monaco-editor@0.38.0/min/vs'
    }
})

pluginMap.forEach(plugin => {
    CinelarTV.use(plugin)
})

/* Remove noscript tag on load */

document.querySelector("noscript")?.remove();

messageBus.start();




CinelarTV.destroy = () => {
    messageBus.stop()
    CinelarTV.unmount()
}

loadPlugins()

import * as jsRoutes from './js-routes';
import loadPlugins from "./pre-initializers/plugin-loader";
window.jsRoutes = jsRoutes;

export default CinelarTV