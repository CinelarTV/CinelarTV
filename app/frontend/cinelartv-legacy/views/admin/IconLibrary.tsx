import { defineComponent, getCurrentInstance } from "vue";
import CIcon from "../../components/c-icon.vue";

export default defineComponent({
    name: "AdminIconsShowcase",
    setup: () => {
        const { appContext } = getCurrentInstance();
        const ALL_ICONS: Set<string> = appContext.config.globalProperties.$iconLibrary.getAllIcons();

        const toKebabCase = (str: string): string => {
            return str.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();
        };

        return () => (
            <div class="py-12 px-4 min-h-screen">
                <h2 class="text-3xl font-bold text-center text-white mb-8 tracking-tight drop-shadow-lg">
                    Showcase de Íconos CinelarTV
                </h2>
                <div class="max-w-6xl mx-auto grid gap-8 grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6">
                    {[...ALL_ICONS.values()].map(icon => (
                        <div class="flex flex-col items-center justify-center bg-white/10 rounded-xl p-6 shadow-lg hover:scale-105 transition-transform duration-200">
                            <div class="bg-gradient-to-tr from-zinc-900 via-zinc-500 to-zinc-500 rounded-full p-4 mb-3 shadow-md">
                                <CIcon size={48} icon={toKebabCase(icon)} class="text-white drop-shadow" />
                            </div>
                            <span class="text-white text-xs font-mono tracking-wide select-all text-center break-all">
                                {toKebabCase(icon)}
                            </span>
                        </div>
                    ))}
                </div>
            </div>
        );
    },
});