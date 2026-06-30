import StyleguideView from '../views/StyleguideView.tsx';

let StyleguideRoute = {
    name: 'styleguide.index',
    path: '/styleguide',
    component: StyleguideView,
    meta: { requireAdmin: true },
    children: [
        {
            path: '',
            redirect: { name: 'styleguide.atoms.buttons' }
        },
        {
            path: 'atoms/buttons',
            name: 'styleguide.atoms.buttons',
            component: () => import('../components/sections/atoms/ButtonsSection.tsx')
        },
        {
            path: 'atoms/inputs',
            name: 'styleguide.atoms.inputs',
            component: () => import('../components/sections/atoms/InputsSection.tsx')
        },
        {
            path: 'atoms/icons',
            name: 'styleguide.atoms.icons',
            component: () => import('../components/sections/atoms/IconsSection.tsx')
        },
        {
            path: 'atoms/spinners',
            name: 'styleguide.atoms.spinners',
            component: () => import('../components/sections/atoms/SpinnersSection.tsx')
        },
        {
            path: 'atoms/colors',
            name: 'styleguide.atoms.colors',
            component: () => import('../components/sections/atoms/ColorsSection.tsx')
        },
        {
            path: 'atoms/typography',
            name: 'styleguide.atoms.typography',
            component: () => import('../components/sections/atoms/TypographySection.tsx')
        },
        {
            path: 'atoms/uploaders',
            name: 'styleguide.atoms.uploaders',
            component: () => import('../components/sections/atoms/UploadersSection.tsx')
        },
        {
            path: 'molecules/content-card',
            name: 'styleguide.molecules.content-card',
            component: () => import('../components/sections/molecules/ContentCardSection.tsx')
        },
        {
            path: 'molecules/content-row',
            name: 'styleguide.molecules.content-row',
            component: () => import('../components/sections/molecules/ContentRowSection.tsx')
        },
        {
            path: 'molecules/forms',
            name: 'styleguide.molecules.forms',
            component: () => import('../components/sections/molecules/FormsSection.tsx')
        },
        {
            path: 'organisms/header',
            name: 'styleguide.organisms.header',
            component: () => import('../components/sections/organisms/HeaderSection.tsx')
        },
        {
            path: 'organisms/modals',
            name: 'styleguide.organisms.modals',
            component: () => import('../components/sections/organisms/ModalsSection.tsx')
        }
    ]
}

export default StyleguideRoute;
