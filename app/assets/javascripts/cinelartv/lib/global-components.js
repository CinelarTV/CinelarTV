const Components = [
    {
        name: 'c-input',
        component: require('../components/forms/c-input.vue').default
    },
    {
        name: 'c-button',
        component: require('../components/forms/c-button.vue').default
    },
    {
        name: 'c-spinner',
        component: require('../components/c-spinner.js').default
    },
    {
        name: 'c-select',
        component: require('../components/forms/c-select.vue').default
    },
    {
        name: 'c-textarea',
        component: require('../components/forms/c-textarea.vue').default
    },
    {
        name: 'c-image-upload',
        component: require('../components/forms/c-image-upload.vue').default
    },
    {
        name: 'plugin-outlet',
        component: require('../components/plugin-outlet.vue').default
    },
    {
        name: 'c-icon-button',
        component: require('../components/forms/c-icon-button.vue').default
    },
]

export default {
    install: (app) => {
        Components.forEach(component => {
            app.component(component.name, component.component)
        })

    }
}