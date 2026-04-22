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
import MessageBus from "./lib/MessageBus";


const CinelarTV = createApp(App)


// Lazy loading para componentes pesados
const loadHeavyComponents = async () => {
    const [VueMonacoEditorPlugin] = await Promise.all([
        import(/* webpackChunkName: "monaco-editor" */ '@guolao/vue-monaco-editor').then(module => module.install),
    ]);

    return { VueMonacoEditorPlugin };
};

// Componentes ligeros que se cargan inmediatamente
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

// Cargar componentes pesados después del montaje inicial
const initializeHeavyComponents = async () => {
    try {
        const { VueMonacoEditorPlugin } = await loadHeavyComponents();

        CinelarTV.use(VueMonacoEditorPlugin, {
            paths: {
                vs: 'https://cdn.jsdelivr.net/npm/monaco-editor@0.38.0/min/vs'
            }
        });

        console.log('🚀 Heavy components loaded asynchronously');
    } catch (error) {
        console.error('❌ Error loading heavy components:', error);
    }
};

// Inicializar componentes pesados en background
setTimeout(initializeHeavyComponents, 100);

pluginMap.forEach(plugin => {
    CinelarTV.use(plugin)
})

/* Remove noscript tag on load */

document.querySelector("noscript")?.remove();

const bus = new MessageBus();

bus.start();

// Make the started instance globally accessible
window.MessageBus = bus;

// Export the instance for importing in components
export const messageBus = bus;

CinelarTV.destroy = () => {
    bus.stop()
    CinelarTV.unmount()
}

import * as jsRoutes from './js-routes';
import loadPlugins from "./pre-initializers/plugin-loader";
window.jsRoutes = jsRoutes;

// Exportar loadPlugins para que boot-cinelartv.ts lo controle con await
export { loadPlugins };
export default CinelarTV