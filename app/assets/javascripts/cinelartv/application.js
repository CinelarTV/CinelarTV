import { createApp } from 'vue/dist/vue.esm-bundler'
import App from './App.vue'
import EssentialsPreloaded from './pre-initializers/essentials-preload';
import preInitializers from './pre-initializers';
import PluginComponents from './lib/plugin-components';
import { createHead } from 'unhead'
import twemoji from './plugins/twemoji'
import AppRouter from './routes/router-map';
const metaManager = createHead()
import Logster from './lib/Logster'
import globalComponents from './lib/global-components';
import I18n from './lib/i18n'
import ColorPicker from './plugins/color-picker'
import * as ConfirmDialog from 'vuejs-confirm-dialog'
import Vue3Toasity from 'vue3-toastify';
import Vue3Progress from "vue3-progress";
import Axios from './lib/Ajax'
import { addCompiledComponent } from './lib/componentManager';
require('./lib/message-bus')
require('./lib/register-service-worker')
import 'vue3-toastify/dist/index.css';
import iconLibrary from './lib/IconLibrary';
import { install as VueMonacoEditorPlugin } from '@guolao/vue-monaco-editor'


const CinelarTV = createApp(App)

CinelarTV.addComponent = addCompiledComponent

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
    PluginComponents,
]

CinelarTV.use(Vue3Progress, {
    color: 'var(--c-tertiary-color)',
    height: '4px'
})

CinelarTV.use(Vue3Toasity, {
    duration: 5000,
    position: 'bottom-center',
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

MessageBus.start();




CinelarTV.destroy = () => {
    MessageBus.stop()
    CinelarTV.unmount()
}

export default CinelarTV