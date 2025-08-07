import { defineComponent, getCurrentInstance } from "vue";
import { useSiteSettings } from "../../app/services/site-settings";
import CIcon from "../../components/c-icon.vue";
import { useIconsStore } from "../../store/icons";

export default defineComponent({
    name: "AdminIconsViewer",
    setup: () => {
        const { appContext } = getCurrentInstance()
        const ALL_ICONS: Set<string> = appContext.config.globalProperties.$iconLibrary.getAllIcons()

        const toKebabCase = (str: string): string => {
            return str.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase();
        };

        return () => (
            <div>
                <h2>
                    Iconos
                </h2>
                <div class="max-w-4xl mx-auto gap-4 grid grid-cols-6">
                    {ALL_ICONS.values().toArray().map(icon => {
                        return (
                            <div class="flex items-center justify-center">
                                <CIcon size={32} icon={toKebabCase(icon)} />
                            </div>
                        )
                    })}
                </div>
            </div >
        )
    },

})