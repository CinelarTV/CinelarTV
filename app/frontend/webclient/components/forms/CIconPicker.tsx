import { defineComponent, ref, computed, watch, onMounted, onBeforeUnmount, PropType } from 'vue';
import {
    TransitionRoot,
    TransitionChild,
    Dialog,
    DialogPanel,
    DialogTitle,
} from '@headlessui/vue';
import CIcon from '../c-icon.vue';

export default defineComponent({
    name: 'CIconPicker',
    props: {
        modelValue: {
            type: String,
            default: '',
        },
        placeholder: {
            type: String,
            default: 'Select icon…',
        },
        label: {
            type: String,
            default: '',
        },
    },
    emits: ['update:modelValue'],
    setup(props, { emit }) {
        const isOpen = ref(false);
        const searchQuery = ref('');
        const allIcons = ref<string[]>([]);
        const loading = ref(true);
        const gridRef = ref<HTMLElement | null>(null);

        const filteredIcons = computed(() => {
            if (!searchQuery.value) return allIcons.value;
            const query = searchQuery.value.toLowerCase().trim();
            return allIcons.value.filter(icon => icon.includes(query));
        });

        const setIsOpen = (value: boolean) => {
            isOpen.value = value;
            if (value) {
                searchQuery.value = '';
            }
        };

        const selectIcon = (icon: string) => {
            emit('update:modelValue', icon);
            setIsOpen(false);
        };

        const clearIcon = () => {
            emit('update:modelValue', '');
        };

        const fetchIcons = async () => {
            loading.value = true;
            try {
                const response = await fetch('/admin/icon-picker/search', {
                    headers: { Accept: 'application/json' },
                });
                if (response.ok) {
                    const data = await response.json();
                    const items = Array.isArray(data) ? data : (data?.icon_picker || data?.icons || []);
                    allIcons.value = items.map((item: { id: string }) => item.id);
                }
            } catch {
                // silent
            } finally {
                loading.value = false;
            }
        };

        onMounted(fetchIcons);

        const focusSearch = () => {
            setTimeout(() => {
                const el = (gridRef.value?.$el || gridRef.value) as HTMLElement | undefined;
                const input = el?.querySelector('input[type="text"]') as HTMLInputElement | null;
                input?.focus();
            }, 100);
        };

        watch(isOpen, (open) => {
            if (open) focusSearch();
        });

        return () => (
            <div class="c-icon-picker">
                {props.label && (
                    <label class="c-icon-picker__label">{props.label}</label>
                )}

                <div class="c-icon-picker__trigger">
                    <button
                        type="button"
                        class="c-icon-picker__button"
                        onClick={() => setIsOpen(true)}
                    >
                        {props.modelValue ? (
                            <span class="c-icon-picker__selected">
                                <CIcon icon={props.modelValue} size={18} />
                                <span class="c-icon-picker__selected-name">{props.modelValue}</span>
                            </span>
                        ) : (
                            <span class="c-icon-picker__placeholder">{props.placeholder}</span>
                        )}
                        <svg class="c-icon-picker__chevron" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M6 9l6 6l6 -6" />
                        </svg>
                    </button>

                    {props.modelValue && (
                        <button
                            type="button"
                            class="c-icon-picker__clear"
                            onClick={clearIcon}
                            title="Clear"
                        >
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M18 6l-12 12" />
                                <path d="M6 6l12 12" />
                            </svg>
                        </button>
                    )}
                </div>

                <TransitionRoot appear show={isOpen.value} as="template">
                    <Dialog as="div" onClose={() => setIsOpen(false)} class="relative z-100">
                        <TransitionChild
                            as="template"
                            enter="duration-200 ease-out"
                            enterFrom="opacity-0"
                            enterTo="opacity-100"
                            leave="duration-150 ease-in"
                            leaveFrom="opacity-100"
                            leaveTo="opacity-0"
                        >
                            <div class="fixed inset-0 bg-black/50 backdrop-blur-sm" />
                        </TransitionChild>

                        <div class="fixed inset-0 flex items-start justify-center pt-[15vh] p-4">
                            <TransitionChild
                                as="template"
                                enter="duration-200 ease-out"
                                enterFrom="opacity-0 scale-95 translate-y-2"
                                enterTo="opacity-100 scale-100 translate-y-0"
                                leave="duration-150 ease-in"
                                leaveFrom="opacity-100 scale-100 translate-y-0"
                                leaveTo="opacity-0 scale-95 translate-y-2"
                            >
                                <DialogPanel
                                    ref={gridRef}
                                    class="c-icon-picker__panel w-full max-w-lg max-h-[70vh] flex flex-col rounded-2xl overflow-hidden shadow-2xl ring-1 ring-[var(--c-primary-400)] bg-[var(--c-primary-600)]"
                                >
                                    <div class="flex items-center justify-between px-5 py-4 border-b border-[var(--c-primary-400)]">
                                        <DialogTitle as="h3" class="text-sm font-semibold text-[var(--c-body-text-color)]">
                                            Select icon
                                        </DialogTitle>
                                        <button
                                            type="button"
                                            class="text-[var(--c-primary-100)] hover:text-[var(--c-body-text-color)] transition-colors"
                                            onClick={() => setIsOpen(false)}
                                        >
                                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <path d="M18 6l-12 12" />
                                                <path d="M6 6l12 12" />
                                            </svg>
                                        </button>
                                    </div>

                                    <div class="px-5 py-3 border-b border-[var(--c-primary-400)]">
                                        <input
                                            type="text"
                                            value={searchQuery.value}
                                            onInput={(e: Event) => (searchQuery.value = (e.target as HTMLInputElement).value)}
                                            placeholder="Search icons…"
                                            class="c-input w-full"
                                            autofocus
                                        />
                                    </div>

                                    <div class="flex-1 overflow-y-auto p-5">
                                        {loading.value ? (
                                            <div class="flex items-center justify-center py-12">
                                                <CIcon icon="loader" size={24} class="animate-spin text-[var(--c-primary-100)]" />
                                            </div>
                                        ) : filteredIcons.value.length > 0 ? (
                                            <div class="grid grid-cols-4 sm:grid-cols-5 md:grid-cols-6 gap-2">
                                                {filteredIcons.value.map(icon => (
                                                    <button
                                                        key={icon}
                                                        type="button"
                                                        class={[
                                                            'c-icon-picker__item',
                                                            props.modelValue === icon && 'c-icon-picker__item--active',
                                                        ]}
                                                        title={icon}
                                                        onClick={() => selectIcon(icon)}
                                                    >
                                                        <CIcon icon={icon} size={20} />
                                                    </button>
                                                ))}
                                            </div>
                                        ) : (
                                            <div class="text-center py-12">
                                                <p class="text-[var(--c-primary-100)] text-sm">
                                                    No icons found
                                                </p>
                                            </div>
                                        )}
                                    </div>
                                </DialogPanel>
                            </TransitionChild>
                        </div>
                    </Dialog>
                </TransitionRoot>
            </div>
        );
    },
});
