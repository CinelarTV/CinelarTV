import { createApp } from 'vue'
import App from './App.vue'
import EssentialsPreloaded from './pre-initializers/essentials-preload';
import '../../builds/cinelartv-wind.css'
import AppRouter from './routes/router-map';
import { createMetaManager } from 'vue-meta'
const metaManager = createMetaManager()
require('./lib/axios-setup')

const CinelarTV = createApp(App)


let pluginMap = [
    EssentialsPreloaded,
    AppRouter,
    metaManager
]

pluginMap.map(plugin => {
    CinelarTV.use(plugin)
})

/* Remove noscript tag on load */

document.querySelector("noscript")?.remove();


export default CinelarTV