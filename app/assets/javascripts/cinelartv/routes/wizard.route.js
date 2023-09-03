
let WizardRoute = {
    name: 'application.wizard',
    path: '/wizard',
    component: () => import(/* webpackChunkName: "wizard" */ '../views/wizard.vue'),
    meta: {
        requireAdmin: true,
        showHeader: false
    },
    children: [
        {
            name: 'wizard.step',
            path: 'steps/:step',
            component: () => import(/* webpackChunkName: "wizard-step" */ '../components/wizard-step.vue'),
            props: true,
            meta: {
                requireAdmin: true,
                showHeader: false
            }
        },
    ]
}



export default WizardRoute

