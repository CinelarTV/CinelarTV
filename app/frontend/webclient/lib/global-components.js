const Components = [
    {
        name: 'c-input',
        component: () => import('../components/forms/c-input.vue')
    },
    {
        name: 'c-button',
        component: () => import('../components/forms/c-button')
    },
    {
        name: 'c-spinner',
        component: () => import('../components/c-spinner.tsx')
    },
    {
        name: 'c-select',
        component: () => import('../components/forms/c-select.vue')
    },
    {
        name: 'c-textarea',
        component: () => import('../components/forms/c-textarea.vue')
    },
    {
        name: 'c-image-upload',
        component: () => import('../components/forms/c-image-upload.vue')
    },
    {
        name: 'plugin-outlet',
        component: () => import('../components/PluginOutlet.tsx')
    },
    {
        name: 'c-icon-button',
        component: () => import('../components/forms/c-icon-button.vue')
    },
    {
        name: 'c-icon',
        component: () => import('../components/c-icon.vue')
    },
    {
        name: 'c-form-row',
        component: () => import('../components/forms/CFormRow.tsx')
    }
]

const isDev = import.meta.env.DEV;

const logComponentRegistration = (name, success = true) => {
    if (isDev) {
        if (success) {
            console.log(` Registered component: ${name}`);
        } else {
            console.error(` Failed to register component: ${name}`);
        }
    }
};

export default {
    install: async (app) => {
        const registrationPromises = Components.map(async (componentDef) => {
            try {
                // Verificar si el componente ya está registrado
                if (app._context.components[componentDef.name]) {
                    logComponentRegistration(componentDef.name, true);
                    return;
                }

                const mod = await componentDef.component();
                const component = mod.default || mod;

                if (!component) {
                    throw new Error(`Component ${componentDef.name} has no default export`);
                }

                app.component(componentDef.name, component);
                logComponentRegistration(componentDef.name, true);

            } catch (error) {
                logComponentRegistration(componentDef.name, false);

                if (isDev) {
                    console.error(`Error registering component ${componentDef.name}:`, error);
                }

                // En producción, no lanzar el error para no romper la app
                if (isDev) {
                    throw error;
                }
            }
        });

        // Esperar a que todos los componentes se registren
        await Promise.allSettled(registrationPromises);

        if (isDev) {
            console.log(' All global components registration completed');
        }
    }
}