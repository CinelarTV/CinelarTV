export default {
    install: (app) => {
        app.component('c-input', require('../components/forms/c-input.vue').default);
        app.component('c-spinner', require('../components/c-spinner.js').default);

    }
}