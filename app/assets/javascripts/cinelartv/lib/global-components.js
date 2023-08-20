export default {
    install: (app) => {
        app.component('c-input', require('../components/forms/c-input.vue').default);

    }
}