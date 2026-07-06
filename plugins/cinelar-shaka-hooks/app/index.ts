import pluginEvents from '@/lib/plugin-events';
import { useSiteSettings } from '@/app/services/site-settings';

const HOOK_COLORS: Record<string, string> = {
    'player:before-init': '#f59e0b',
    'player:after-init': '#10b981',
    'player:before-load': '#3b82f6',
    'player:after-load': '#8b5cf6',
    'player:destroy': '#ef4444',
    'player:playback-start': '#06b6d4',
    'player:playback-pause': '#f97316',
};

function logHook(hook: string, data: any) {
    const color = HOOK_COLORS[hook] || '#888';
    const label = `%c[ShakaHooks] ${hook}`;
    const style = `color: ${color}; font-weight: bold; font-size: 12px;`;

    console.groupCollapsed(label, style);

    if (data.player) {
        console.log('Player:', data.player);
    }
    if (data.netEngine) {
        console.log('NetworkingEngine:', data.netEngine);
    }
    if (data.video) {
        console.log('Video element:', data.video);
    }
    if (data.src) {
        console.log('Source:', data.src);
    }
    if (data.duration !== undefined) {
        console.log('Duration:', data.duration);
    }
    if (data.configure) {
        console.log('configure() available — call ctx.configure({...}) to modify Shaka config');
    }
    if (data.contentId) {
        console.log('Content ID:', data.contentId);
    }
    if (data.episodeId) {
        console.log('Episode ID:', data.episodeId);
    }
    if (data.currentTime !== undefined) {
        console.log('Current time:', data.currentTime);
    }

    // Dump full context
    const { player, netEngine, video, configure, ...rest } = data;
    const contextDump = { ...rest };
    if (player) contextDump.player = 'shaka.Player instance';
    if (netEngine) contextDump.netEngine = 'shaka.net.NetworkingEngine instance';
    if (video) contextDump.video = `HTMLVideoElement <${video.tagName}>`;
    if (configure) contextDump.configure = 'function(cfg)';
    console.log('Full context:', contextDump);

    console.groupEnd();
}

export default {
    name: 'cinelar-shaka-hooks',
    version: '0.1.0',
    init() {
        const { siteSettings } = useSiteSettings();
        if (!siteSettings?.cinelar_shaka_hooks_enabled) return;

        console.log(
            '%c[ShakaHooks] Plugin enabled — logging all player lifecycle hooks',
            'color: #10b981; font-weight: bold;'
        );

        const hooks = [
            'player:before-init',
            'player:after-init',
            'player:before-load',
            'player:after-load',
            'player:destroy',
            'player:playback-start',
            'player:playback-pause',
        ] as const;

        for (const hook of hooks) {
            pluginEvents.on(hook, (ctx) => logHook(hook, ctx));
        }
    }
};
