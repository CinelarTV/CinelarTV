import { pluginEvents } from "@/lib/plugin-events";
import { registerPluginOutlet, type PluginOutletRegistration } from "@/components/PluginOutlet";
import { useSiteSettings } from "@/app/services/site-settings";

export const PLUGIN_API_VERSION = "1.0.0";

export type PluginDefinition = {
  id: string;
  setup: (api: PluginApi) => void | (() => void) | Promise<void | (() => void)>;
};

export type PluginRegistryEntry = {
  id: string;
  version: string;
  entry: string;
  dependencies?: Record<string, string>;
  status?: "enabled" | "blocked" | "failed";
  reason?: string;
};

export type PluginApi = {
  readonly pluginId: string;
  outlets: { register: (name: string, registration: Omit<PluginOutletRegistration, "pluginId">) => () => void };
  routes: { add: (route: any) => () => void };
  events: typeof pluginEvents;
  settings: { get: (key: string) => unknown };
  http: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;
  lifecycle: { onDispose: (callback: () => void | Promise<void>) => void };
  navigation: { add: (item: unknown) => () => void };
};

export function definePlugin(plugin: PluginDefinition): PluginDefinition {
  if (!plugin?.id || typeof plugin.setup !== "function") {
    throw new Error("A plugin must provide an id and setup(api) function");
  }
  return plugin;
}

export class PluginHost {
  private readonly disposers = new Map<string, Array<() => void | Promise<void>>>();
  private readonly navigationItems = new Map<string, unknown[]>();
  private readonly initializedIds = new Set<string>();

  constructor(private readonly registry: PluginRegistryEntry[]) {}

  async initialize(): Promise<void> {
    for (const entry of this.registry) {
      if (entry.status && entry.status !== "enabled") {
        console.warn(`[PluginHost] ${entry.id} is ${entry.status}: ${entry.reason || "unknown reason"}`);
        continue;
      }

      try {
        // Plugin URLs are server-generated, fingerprinted assets. Vite must not
        // transform this dynamic import back into a source import.
        const module = await import(/* @vite-ignore */ entry.entry);
        await this.initializeDefinition(entry.id, module.default);
        console.info(`[PluginHost] initialized ${entry.id}@${entry.version}`);
      } catch (error) {
        console.error(`[PluginHost] failed to initialize ${entry.id}`, error);
      }
    }
  }

  async initializeDefinition(expectedId: string, definition: PluginDefinition | { init?: () => unknown }): Promise<void> {
    if (this.initializedIds.has(expectedId)) {
      console.warn(`[PluginHost] ${expectedId} already initialized, skipping duplicate`);
      return;
    }
    const plugin = definition as PluginDefinition;
    if (plugin?.setup) {
      if (plugin.id !== expectedId) throw new Error(`entry exported ${plugin.id || "nothing"}, expected ${expectedId}`);
      this.initializedIds.add(expectedId);
      const result = await plugin.setup(this.apiFor(expectedId));
      if (typeof result === "function") this.onDispose(expectedId, result);
      return;
    }
    if (typeof (definition as any)?.init === "function") {
      console.warn(`[PluginHost] ${expectedId} uses deprecated init(); migrate to definePlugin({ id, setup })`);
      this.initializedIds.add(expectedId);
      await (definition as any).init();
      return;
    }
    throw new Error("entry has neither setup(api) nor legacy init()");
  }

  async dispose(pluginId?: string): Promise<void> {
    const ids = pluginId ? [pluginId] : [...this.disposers.keys()].reverse();
    for (const id of ids) {
      const callbacks = this.disposers.get(id) || [];
      this.disposers.delete(id);
      for (const callback of callbacks.reverse()) await callback();
    }
  }

  private apiFor(pluginId: string): PluginApi {
    return {
      pluginId,
      outlets: {
        register: (name, registration) => {
          const dispose = registerPluginOutlet(name, { ...registration, pluginId });
          this.onDispose(pluginId, dispose);
          return dispose;
        },
      },
      routes: {
        add: (route) => {
          const router = (window as any).AppRouter;
          if (!router) throw new Error("Router is not available yet");
          const dispose = router.addRoute({ ...route, meta: { ...route.meta, plugin: pluginId } });
          this.onDispose(pluginId, dispose);
          return dispose;
        },
      },
      events: pluginEvents,
      settings: { get: (key) => useSiteSettings().siteSettings?.[key] },
      http: (input, init = {}) => {
        const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");
        const headers = new Headers(init.headers);
        if (csrf) headers.set("X-CSRF-Token", csrf);
        return fetch(input, { credentials: "same-origin", ...init, headers });
      },
      lifecycle: { onDispose: (callback) => this.onDispose(pluginId, callback) },
      navigation: {
        add: (item) => {
          const items = this.navigationItems.get(pluginId) || [];
          items.push(item);
          this.navigationItems.set(pluginId, items);
          return () => this.navigationItems.set(pluginId, (this.navigationItems.get(pluginId) || []).filter((candidate) => candidate !== item));
        },
      },
    };
  }

  private onDispose(pluginId: string, callback: () => void | Promise<void>): void {
    const callbacks = this.disposers.get(pluginId) || [];
    callbacks.push(callback);
    this.disposers.set(pluginId, callbacks);
  }
}

export function createPluginHost(registry: PluginRegistryEntry[] = []): PluginHost {
  return new PluginHost(registry);
}
