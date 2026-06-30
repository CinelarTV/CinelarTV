import { defineComponent, getCurrentInstance, ref, computed } from "vue";
import CIcon from "../../components/c-icon.vue";
import CInput from "@/components/forms/c-input.vue";

export default defineComponent({
    name: "AdminIconsShowcase",
    setup: () => {
        const { appContext } = getCurrentInstance()!;
        const rawIcons: Set<string> = appContext.config.globalProperties.$iconLibrary?.getAllIcons() || new Set();

        // Estados reactivos
        const searchQuery = ref("");
        const copiedIcon = ref<string | null>(null);

        // Funciones de utilidad
        const toKebabCase = (str: string): string => {
            return str.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();
        };

        // Mapeamos los íconos una sola vez para mejorar el rendimiento
        const allIcons = Array.from(rawIcons).map(toKebabCase);

        // Computed para el buscador
        const filteredIcons = computed(() => {
            if (!searchQuery.value) return allIcons;
            const query = searchQuery.value.toLowerCase().trim();
            return allIcons.filter(icon => icon.includes(query));
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
                console.error("Error al copiar al portapapeles:", err);
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
                    {/* Grilla de Íconos o Estado Vacío */}
                    {filteredIcons.value.length > 0 ? (
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

                                    {/* Tooltip flotante */}
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