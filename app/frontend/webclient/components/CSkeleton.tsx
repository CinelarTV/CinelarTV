import { defineComponent, PropType } from 'vue';

export default defineComponent({
    name: 'CSkeleton',
    props: {
        variant: {
            type: String as PropType<'text' | 'circle' | 'rect' | 'card' | 'avatar-text'>,
            default: 'text'
        },
        width: {
            type: String,
            default: '100%'
        },
        height: {
            type: String,
            default: undefined
        },
        count: {
            type: Number,
            default: 1
        },
        animated: {
            type: Boolean,
            default: true
        }
    },
    setup(props) {
        const defaultHeights: Record<string, string> = {
            text: '14px',
            circle: '48px',
            rect: '120px',
            card: '180px',
            'avatar-text': '48px'
        };

        const skeletonStyle = (override?: string) => ({
            width: props.width,
            height: override || props.height || defaultHeights[props.variant]
        });

        const renderSkeleton = (index: number) => {
            if (props.variant === 'card') {
                return (
                    <div key={index} class="c-skeleton-card">
                        <div
                            class={['c-skeleton', 'c-skeleton--rect', props.animated && 'c-skeleton--animated']}
                            style={{ width: '100%', height: '120px' }}
                        />
                        <div class="c-skeleton-card__body">
                            <div
                                class={['c-skeleton', 'c-skeleton--text', props.animated && 'c-skeleton--animated']}
                                style={{ width: '90%', height: '12px' }}
                            />
                            <div
                                class={['c-skeleton', 'c-skeleton--text', props.animated && 'c-skeleton--animated']}
                                style={{ width: '75%', height: '12px' }}
                            />
                            <div
                                class={['c-skeleton', 'c-skeleton--text', props.animated && 'c-skeleton--animated']}
                                style={{ width: '50%', height: '12px' }}
                            />
                        </div>
                    </div>
                );
            }

            if (props.variant === 'avatar-text') {
                return (
                    <div key={index} class="c-skeleton-avatar-text">
                        <div
                            class={['c-skeleton', 'c-skeleton--circle', props.animated && 'c-skeleton--animated']}
                            style={{ width: '40px', height: '40px', flexShrink: 0 }}
                        />
                        <div class="c-skeleton-avatar-text__lines">
                            <div
                                class={['c-skeleton', 'c-skeleton--text', props.animated && 'c-skeleton--animated']}
                                style={{ width: '80%', height: '12px' }}
                            />
                            <div
                                class={['c-skeleton', 'c-skeleton--text', props.animated && 'c-skeleton--animated']}
                                style={{ width: '50%', height: '12px' }}
                            />
                        </div>
                    </div>
                );
            }

            return (
                <div
                    key={index}
                    class={[
                        'c-skeleton',
                        `c-skeleton--${props.variant}`,
                        props.animated && 'c-skeleton--animated'
                    ]}
                    style={skeletonStyle()}
                />
            );
        };

        return () => (
            <div class="c-skeleton-group">
                {Array.from({ length: props.count }, (_, i) => renderSkeleton(i))}
            </div>
        );
    }
});
