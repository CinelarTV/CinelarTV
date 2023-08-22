import { createApp } from 'vue'
import App from './App.vue'
import EssentialsPreloaded from './pre-initializers/essentials-preload';
import AppRouter from './routes/router-map';
import { createMetaManager } from 'vue-meta'
import twemoji from './plugins/twemoji'
const metaManager = createMetaManager()
import Logster from './lib/logster'
import globalComponents from './lib/global-components';
import I18n from './lib/i18n'
import ColorPicker from './plugins/color-picker'
import * as ConfirmDialog from 'vuejs-confirm-dialog'
import { createPinia } from 'pinia'
require('./lib/axios-setup')
require('./lib/message-bus')

const CinelarTV = createApp(App)
const pinia = createPinia()



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
    pinia
]

pluginMap.map(plugin => {
    CinelarTV.use(plugin)
})

/* Remove noscript tag on load */

document.querySelector("noscript")?.remove();

MessageBus.start();


export default CinelarTV