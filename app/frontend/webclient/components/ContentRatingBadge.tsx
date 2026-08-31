import { defineComponent, ref, computed, PropType, onMounted, onBeforeUnmount } from 'vue';

interface ContentRating {
    code: string;
    system: string;
    name: string;
    description?: string;
    min_age?: number;
    color?: string;
}

interface ContentDescriptor {
    key: string;
    name: string;
    category?: string;
    severity_level?: number;
}

export default defineComponent({
    name: 'ContentRatingBadge',
    props: {
        rating: {
            type: Object as PropType<ContentRating>,
            default: null
        },
        descriptors: {
            type: Array as PropType<ContentDescriptor[]>,
            default: () => []
        },
        compact: {
            type: Boolean,
            default: false
        },
        position: {
            type: String as PropType<'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'>,
            default: 'top-left'
        },
        autoHide: {
            type: Boolean,
            default: false
        },
        hideDelay: {
            type: Number,
            default: 5000
        }
    },
    setup(props) {
        const visible = ref(true);
        const faded = ref(false);
        let hideTimer: ReturnType<typeof setTimeout> | null = null;

        const positionClasses = computed(() => {
            const map: Record<string, string> = {
                'top-left': 'top-4 left-4',
                'top-right': 'top-4 right-4',
                'bottom-left': 'bottom-20 left-4',
                'bottom-right': 'bottom-20 right-4'
            };
            return map[props.position] || map['top-left'];
        });

        const badgeStyle = computed(() => {
            if (!props.rating?.color || props.rating.color === '#ffffff') return {};
            return { borderColor: props.rating.color };
        });

        const advisoryText = computed(() => {
            if (!props.rating) return '';
            const descriptorNames = props.descriptors.slice(0, 3).map(d => d.name);
            if (descriptorNames.length === 0) return props.rating.name;
            return `${props.rating.name} \u00b7 ${descriptorNames.join(', ')}`;
        });

        const startHideTimer = () => {
            if (!props.autoHide) return;
            hideTimer = setTimeout(() => {
                faded.value = true;
                setTimeout(() => {
                    visible.value = false;
                }, 500);
            }, props.hideDelay);
        };

        onMounted(() => {
            startHideTimer();
        });

        onBeforeUnmount(() => {
            if (hideTimer) clearTimeout(hideTimer);
        });

        return () => {
            if (!props.rating || !visible.value) return null;

            if (props.compact) {
                return (
                    <div
                        class={[
                            'content-rating-badge content-rating-badge--compact',
                            positionClasses.value,
                            faded.value ? 'content-rating-badge--faded' : ''
                        ]}
                        style={badgeStyle.value}
                    >
                        <span class="content-rating-badge__code">{props.rating.name}</span>
                    </div>
                );
            }

            return (
                <div
                    class={[
                        'content-rating-badge content-rating-badge--full',
                        positionClasses.value,
                        faded.value ? 'content-rating-badge--faded' : ''
                    ]}
                >
                    <div class="content-rating-badge__header">
                        <span class="content-rating-badge__code">{props.rating.name}</span>
                        {props.rating.description && (
                            <span class="content-rating-badge__desc">{props.rating.description}</span>
                        )}
                    </div>
                    {props.descriptors.length > 0 && (
                        <div class="content-rating-badge__descriptors">
                            {props.descriptors.slice(0, 4).map(d => (
                                <span key={d.key} class="content-rating-badge__descriptor">
                                    {d.name}
                                </span>
                            ))}
                        </div>
                    )}
                </div>
            );
        };
    }
});
