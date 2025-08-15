import CIcon from "@/components/c-icon.vue";
import i18n from "@/lib/i18n";
import { defineComponent, getCurrentInstance, ref } from "vue";

export default defineComponent({
    name: "WatchPartyToggle",
    setup() {
        const opened = ref(false);
        const { $t } = getCurrentInstance()!.appContext.config.globalProperties;

        const onClick = () => {
            opened.value = !opened.value;
            const event = new CustomEvent('watchparty-toggle', {
                detail: { opened: opened.value }
            });
            window.dispatchEvent(event);
        };

        return () => (
            <media-tooltip class="contents">
                <media-tooltip-trigger>
                    <button
                        onClick={onClick}
                        class="group relative flex size-10 cursor-pointer items-center justify-center rounded-md outline-none ring-inset ring-sky-400 hover:bg-white/20 data-[focus]:ring-4">
                        <CIcon icon={opened.value ? "message-circle-off" : "message-circle-more"} />
                    </button>
                </media-tooltip-trigger>
                <media-tooltip-content
                    class="z-10 rounded-sm border border-gray-400/20 bg-black/90 px-2 py-0.5 text-sm font-medium text-white animate-fade-out animate-duration-200 data-[visible]:animate-fade-in data-[visible]:animate-duration-100"
                    placement="top start"
                >
                    {$t('js.watchparty.toggler')}
                </media-tooltip-content>
            </media-tooltip>

        );
    }
});