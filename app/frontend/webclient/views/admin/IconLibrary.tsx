import { defineComponent, ref, computed, onMounted } from "vue";
import CIcon from "../../components/c-icon.vue";
import CInput from "@/components/forms/c-input.vue";

export default defineComponent({
    name: "AdminIconsShowcase",
    setup: () => {
        // Estados reactivos
        const searchQuery = ref("");
        const copiedIcon = ref<string | null>(null);
        const allIcons = ref<string[]>([]);
        const loading = ref(true);

        // Detectar si usamos server sprite
        const getSpritePath = (): string | null => {
            try {
                const el = document.getElementById("data-preloaded");
                if (!el?.dataset.preloaded) return null;
                const data = JSON.parse(el.dataset.preloaded);
                return data.svgSpritePath || null;
            } catch {
                return null;
            }
        };

        // Cargar iconos
        onMounted(async () => {
            const spritePath = getSpritePath();

            if (spritePath) {
                // Server-side: fetch from admin endpoint
                try {
                    const response = await fetch("/admin/icon-picker/search", {
                        headers: { "Accept": "application/json" }
                    });
                    if (response.ok) {
                        const contentType = response.headers.get("content-type") || "";
                        if (contentType.includes("application/json")) {
                            const data = await response.json();
                            if (Array.isArray(data)) {
                                allIcons.value = data.map((item: { id: string }) => item.id);
                            }
                        }
                    }
                } catch (err) {
                    console.warn("[IconLibrary] Server icon-picker unavailable, falling back to client-side");
                }
            }

            // Fallback: if no icons loaded from server, use client-side
            if (allIcons.value.length === 0) {
                try {
                    const { getCurrentInstance } = await import("vue");
                    const instance = getCurrentInstance();
                    const rawIcons: Set<string> = instance?.appContext.config.globalProperties.$iconLibrary?.getAllIcons() || new Set();
                    allIcons.value = Array.from(rawIcons);
                } catch {
                    // Final fallback: empty
                }
            }

            loading.value = false;
        });

        // Computed para el buscador
        const filteredIcons = computed(() => {
            if (!searchQuery.value) return allIcons.value;
            const query = searchQuery.value.toLowerCase().trim();
            return allIcons.value.filter(icon => icon.includes(query));
        });

        // Lógica para copiar
        const copyToClipboard = async (iconName: string) => {
            try {
                await navigator.clipboard.writeText(iconName);
                copiedIcon.value = iconName;

                setTimeout(() => {
                    if (copiedIcon.value === iconName) {
                        copiedIcon.value = null;
                    }
                }, 2000);
            } catch (err) {
                console.error("Error copying to clipboard:", err);
            }
        };

        // Función de renderizado (JSX)
        return () => (
            <div class="panel">
                <div class="panel-header">
                    <h2 class="panel-title">Icon Library</h2>
                    <div class="mb-4 max-w-xs">
                        <CInput
                            v-model={searchQuery.value}
                            placeholder="Search icon..."
                            class="w-full"
                        />
                    </div>
                </div>
                <div class="panel-body">
                    {loading.value ? (
                        <div class="text-center py-12">
                            <p class="text-[var(--c-primary-100)] text-sm">Loading icons...</p>
                        </div>
                    ) : filteredIcons.value.length > 0 ? (
                        <div class="grid gap-4 grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8">
                            {filteredIcons.value.map(icon => (
                                <button
                                    key={icon}
                                    onClick={() => copyToClipboard(icon)}
                                    class="group flex flex-col items-center justify-center bg-[rgba(255,255,255,0.03)] rounded-xl p-4 border border-[rgba(255,255,255,0.08)] hover:bg-[rgba(255,255,255,0.06)] hover:border-[rgba(255,255,255,0.15)] hover:-translate-y-1 transition-all duration-200 cursor-pointer relative"
                                    title={`Copy ${icon}`}
                                >
                                    <div class="bg-[rgba(255,255,255,0.05)] group-hover:bg-[rgba(255,255,255,0.1)] rounded-full p-3 mb-3 transition-colors duration-200">
                                        <CIcon
                                            size={24}
                                            icon={icon}
                                            class="text-[var(--c-body-text-color)] group-hover:text-[var(--c-tertiary-300)] transition-colors duration-200"
                                        />
                                    </div>

                                    <span class="text-[var(--c-primary-100)] text-xs font-mono tracking-wide text-center break-all">
                                        {icon}
                                    </span>

                                    {copiedIcon.value === icon && (
                                        <div class="absolute -top-10 bg-[var(--c-primary-300)] text-white text-xs font-medium px-3 py-1.5 rounded-lg shadow-lg pointer-events-none">
                                            Copied!
                                        </div>
                                    )}
                                </button>
                            ))}
                        </div>
                    ) : (
                        <div class="text-center py-12">
                            <p class="text-[var(--c-primary-100)] text-sm">
                                No icons found matching "<span class="font-semibold">{searchQuery.value}</span>"
                            </p>
                        </div>
                    )}
                </div>
            </div>
        );
    },
});
