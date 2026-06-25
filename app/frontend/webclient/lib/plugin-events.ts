// Frontend event bus for plugins
// Allows plugins to react to core events without direct coupling
// Usage: pluginEvents.on('playback:start', (data) => { ... })
//        pluginEvents.emit('navigation', '/watch/123')

type Listener = (...args: any[]) => void;

const listeners = new Map<string, Set<Listener>>();

export const pluginEvents = {
    on(event: string, fn: Listener) {
        if (!listeners.has(event)) {
            listeners.set(event, new Set());
        }
        listeners.get(event)!.add(fn);
        return () => fn && listeners.get(event)?.delete(fn);
    },

    off(event: string, fn: Listener) {
        listeners.get(event)?.delete(fn);
    },

    emit(event: string, ...args: any[]) {
        listeners.get(event)?.forEach(fn => {
            try {
                fn(...args);
            } catch (e) {
                console.error(`[plugin-events] Error in handler for "${event}":`, e);
            }
        });
    },

    clear(event?: string) {
        if (event) {
            listeners.delete(event);
        } else {
            listeners.clear();
        }
    }
};

export default pluginEvents;
