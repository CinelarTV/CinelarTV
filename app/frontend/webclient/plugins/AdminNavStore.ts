import { reactive } from "vue";

export type AdminTab = {
  label: string;
  icon?: string;
  route?: string;
  path?: string;
  pluginId: string;
  priority?: number;
};

const state = reactive<{ tabs: AdminTab[] }>({ tabs: [] });

export function registerAdminTab(tab: AdminTab): () => void {
  state.tabs.push(tab);
  state.tabs.sort((a, b) => (a.priority ?? 100) - (b.priority ?? 100));
  return () => {
    const idx = state.tabs.indexOf(tab);
    if (idx !== -1) state.tabs.splice(idx, 1);
  };
}

export function getPluginAdminTabs(): AdminTab[] {
  return state.tabs;
}
