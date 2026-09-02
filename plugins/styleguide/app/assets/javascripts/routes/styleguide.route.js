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
            path: 'atoms/alerts',
            name: 'styleguide.atoms.alerts',
            component: () => import('../components/sections/atoms/AlertsSection.tsx')
        },
        {
            path: 'atoms/badges',
            name: 'styleguide.atoms.badges',
            component: () => import('../components/sections/atoms/BadgesSection.tsx')
        },
        {
            path: 'atoms/pagination',
            name: 'styleguide.atoms.pagination',
            component: () => import('../components/sections/atoms/PaginationSection.tsx')
        },
        {
            path: 'atoms/skeletons',
            name: 'styleguide.atoms.skeletons',
            component: () => import('../components/sections/atoms/SkeletonsSection.tsx')
        },
        {
            path: 'atoms/tooltips',
            name: 'styleguide.atoms.tooltips',
            component: () => import('../components/sections/atoms/TooltipsSection.tsx')
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
            path: 'molecules/content-rating-badge',
            name: 'styleguide.molecules.content-rating-badge',
            component: () => import('../components/sections/molecules/ContentRatingBadgeSection.tsx')
        },
        {
            path: 'molecules/tables',
            name: 'styleguide.molecules.tables',
            component: () => import('../components/sections/molecules/TablesSection.tsx')
        },
        {
            path: 'molecules/tabs',
            name: 'styleguide.molecules.tabs',
            component: () => import('../components/sections/molecules/TabsSection.tsx')
        },
        {
            path: 'molecules/stats',
            name: 'styleguide.molecules.stats',
            component: () => import('../components/sections/molecules/StatsSection.tsx')
        },
        {
            path: 'molecules/dropdowns',
            name: 'styleguide.molecules.dropdowns',
            component: () => import('../components/sections/molecules/DropdownsSection.tsx')
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
