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
        component: () => import('../components/c-spinner.js')
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
        component: () => import('../components/plugin-outlet.vue')
    },
    {
        name: 'c-icon-button',
        component: () => import('../components/forms/c-icon-button.vue')
    },
    {
        name: 'c-icon',
        component: () => import('../components/c-icon.vue')
    }
]

export default {
    install: (app) => {
        Components.forEach(async component => {
            const mod = await component.component();
            app.component(component.name, mod.default || mod);
            console.log(`Registered component: ${component.name}`);
        })
    }
}