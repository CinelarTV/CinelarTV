/* 
    This file has been created to provide Types to vue-monaco-editor 
    We should use the window.monaco global variable to access the Monaco Editor API
    
*/


class MonacoTools {
    constructor() {
        throw new Error('This class should not be instantiated');
    }

    static get monaco() {
        return (window as any).monaco;
    }

    static get editor() {
        return (window as any).monaco.editor;
    }

    static get languages() {
        return (window as any).monaco.languages;
    }        

    public static addTypes() {
        if (!(window as any).monaco) {
            console.error('Monaco Editor is not loaded');
            return;
        }

        (window as any).monaco.languages.typescript.typescriptDefaults.addExtraLib(
            // window.PluginAPI is an instance of PluginAPI
            require('../../types/plugin-api.d.ts').default, "plugin-api.d.ts"
        );
        (window as any).monaco.languages.typescript.typescriptDefaults.addExtraLib(
            require('!!raw-loader!../../lib/PluginAPI.ts').default, "file:///plugin-api.d.ts"
        );

        console.log('Types added to Monaco Editor');
    }

    
}

export default MonacoTools;