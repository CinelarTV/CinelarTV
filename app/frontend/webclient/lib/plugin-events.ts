// Frontend event bus for plugins
// Allows plugins to react to core events without direct coupling

type Listener = (...args: any[]) => void;

// ─── Player Lifecycle Hook Types ──────────────────────────────────────────────

export interface PlayerBeforeInitContext {
    video: HTMLVideoElement;
    configure: (config: Record<string, any>) => void;
}

export interface PlayerAfterInitContext {
    player: any; // shaka.Player
    video: HTMLVideoElement;
    netEngine: any; // shaka.net.NetworkingEngine
}

export interface PlayerBeforeLoadContext {
    player: any;
    src: string;
}

export interface PlayerAfterLoadContext {
    player: any;
    video: HTMLVideoElement;
    duration: number;
}

export interface PlayerDestroyContext {
    player: any | null;
}

export interface PlayerPlaybackStartContext {
    player: any | null;
    contentId: string;
    episodeId?: string;
}

export interface PlayerPlaybackPauseContext {
    player: any | null;
    contentId: string;
    episodeId?: string;
    currentTime: number;
}

// ─── Event Map (for typed emits) ─────────────────────────────────────────────

export interface PluginEventMap {
    'player:before-init': PlayerBeforeInitContext;
    'player:after-init': PlayerAfterInitContext;
    'player:before-load': PlayerBeforeLoadContext;
    'player:after-load': PlayerAfterLoadContext;
    'player:destroy': PlayerDestroyContext;
    'player:playback-start': PlayerPlaybackStartContext;
    'player:playback-pause': PlayerPlaybackPauseContext;
    'navigation': { to: any; from: any };
    [key: string]: any;
}

// ─── Event Bus ────────────────────────────────────────────────────────────────

const listeners = new Map<string, Set<Listener>>();

export const pluginEvents = {
    on<K extends keyof PluginEventMap>(event: K, fn: (ctx: PluginEventMap[K]) => void): () => void {
        if (!listeners.has(event)) {
            listeners.set(event, new Set());
        }
        listeners.get(event)!.add(fn);
        return () => fn && listeners.get(event)?.delete(fn);
    },

    off<K extends keyof PluginEventMap>(event: K, fn: (ctx: PluginEventMap[K]) => void): void {
        listeners.get(event)?.delete(fn);
    },

    emit<K extends keyof PluginEventMap>(event: K, ...args: PluginEventMap[K] extends void ? [] : [PluginEventMap[K]]): void {
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
