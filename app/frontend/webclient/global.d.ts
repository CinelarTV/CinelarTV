
import 'vue-router'

// To ensure it is treated as a module, add at least one `export` statement
export { }

declare module 'vue-router' {
    interface RouteMeta {
        transition?: string
        requiresAuth?: boolean
    }

    interface RouteLocationAsRelativeGeneric {
        meta?: RouteMeta
    }

    interface RouteLocationAsPathGeneric {
        meta?: RouteMeta
    }
}