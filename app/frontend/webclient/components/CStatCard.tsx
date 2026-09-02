import { defineComponent, PropType } from 'vue';
import CIcon from './c-icon.vue';

export default defineComponent({
    name: 'CStatCard',
    props: {
        label: {
            type: String,
            required: true
        },
        value: {
            type: [String, Number],
            required: true
        },
        icon: {
            type: String,
            default: ''
        },
        trend: {
            type: String as PropType<'up' | 'down' | null>,
            default: null
        },
        trendValue: {
            type: String,
            default: ''
        },
        trendLabel: {
            type: String,
            default: ''
        },
        color: {
            type: String as PropType<'primary' | 'info' | 'success' | 'warning' | 'danger'>,
            default: undefined
        },
        variant: {
            type: String as PropType<'default' | 'accent'>,
            default: 'default'
        }
    },
    setup(props, { slots }) {
        return () => (
            <div class={[
                'c-stat-card',
                props.variant === 'accent' && 'c-stat-card--accent',
                props.color && `c-stat-card--${props.color}`
            ]}>
                {props.variant === 'accent' && props.icon && (
                    <div class="c-stat-card__icon">
                        <CIcon icon={props.icon} size={24} />
                    </div>
                )}
                {props.variant !== 'accent' && (
                    <div class="c-stat-card__header">
                        <span class="c-stat-card__label">{props.label}</span>
                        {props.icon && <CIcon icon={props.icon} size={18} />}
                    </div>
                )}
                <div class="c-stat-card__value">{props.value}</div>
                {props.variant === 'accent' && (
                    <div class="c-stat-card__label">{props.label}</div>
                )}
                {props.trend && (
                    <div class={`c-stat-card__trend c-stat-card__trend--${props.trend}`}>
                        <CIcon icon={props.trend === 'up' ? 'trending-up' : 'trending-down'} size={14} />
                        <span>{props.trendValue}</span>
                        {props.trendLabel && <span class="c-stat-card__trend-label">{props.trendLabel}</span>}
                    </div>
                )}
                {slots.default?.()}
            </div>
        );
    }
});
