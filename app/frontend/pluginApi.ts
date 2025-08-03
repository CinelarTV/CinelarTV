// API para registro de plugins en el frontend
// Puedes expandirla según tus necesidades

import React from 'react';

// Tipos
export type Route = { path: string; component: React.ComponentType<any> };
export type OutletComponent = React.ReactNode | (() => React.ReactNode);

// Almacenamiento interno
const routes: Route[] = [];
const outlets: Record<string, OutletComponent[]> = {};

// API
export const pluginApi = {
    registerRoute(route: Route) {
        routes.push(route);
    },
    getRoutes(): Route[] {
        return routes;
    },
    registerOutlet(name: string, component: OutletComponent) {
        if (!outlets[name]) outlets[name] = [];
        outlets[name].push(component);
    },
    getOutletComponents(name: string): OutletComponent[] {
        return outlets[name] || [];
    }
};

// Componente Outlet
export const PluginOutlet: React.FC<{ name: string }> = ({ name }) => {
    const comps = pluginApi.getOutletComponents(name);
    return <>{ comps.map((Comp, i) => (typeof Comp === 'function' ? <Comp key= { i } /> : Comp)) } </>;
};

// Ejemplo de uso en un plugin:
// import { pluginApi } from './pluginApi';
// pluginApi.registerRoute({ path: '/mi-plugin', component: MiPluginComponent });
// pluginApi.registerOutlet('sidebar', <MiSidebarComponent />);
