import { defineComponent } from 'vue';

const colorGroups = [
    {
        name: 'Primary',
        colors: [
            { var: '--c-primary-50', label: '50' },
            { var: '--c-primary-100', label: '100' },
            { var: '--c-primary-200', label: '200' },
            { var: '--c-primary-300', label: '300' },
            { var: '--c-primary-400', label: '400' },
            { var: '--c-primary-500', label: '500' },
            { var: '--c-primary-600', label: '600' },
            { var: '--c-primary-700', label: '700' },
            { var: '--c-primary-800', label: '800' },
            { var: '--c-primary-900', label: '900' }
        ]
    },
    {
        name: 'Secondary',
        colors: [
            { var: '--c-secondary-50', label: '50' },
            { var: '--c-secondary-100', label: '100' },
            { var: '--c-secondary-200', label: '200' },
            { var: '--c-secondary-300', label: '300' },
            { var: '--c-secondary-400', label: '400' },
            { var: '--c-secondary-500', label: '500' },
            { var: '--c-secondary-600', label: '600' },
            { var: '--c-secondary-700', label: '700' },
            { var: '--c-secondary-800', label: '800' },
            { var: '--c-secondary-900', label: '900' }
        ]
    },
    {
        name: 'Semantic',
        colors: [
            { var: '--c-success', label: 'Success' },
            { var: '--c-warning', label: 'Warning' },
            { var: '--c-danger', label: 'Danger' },
            { var: '--c-info', label: 'Info' }
        ]
    },
    {
        name: 'Surface',
        colors: [
            { var: '--c-body-bg', label: 'Body BG' },
            { var: '--c-body-text-color', label: 'Body Text' },
            { var: '--c-surface', label: 'Surface' },
            { var: '--c-border', label: 'Border' }
        ]
    }
];

export default defineComponent({
    name: 'ColorsSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Colors</h1>
                <p class="styleguide-section__description">
                    Paleta de colores del sistema basada en CSS variables.
                </p>

                {colorGroups.map(group => (
                    <div class="styleguide-subsection" key={group.name}>
                        <h2 class="styleguide-subsection__title">{group.name}</h2>
                        <div class="styleguide-color-grid">
                            {group.colors.map(color => (
                                <div class="styleguide-color-swatch" key={color.var}>
                                    <div
                                        class="styleguide-color-swatch__preview"
                                        style={{ backgroundColor: `var(${color.var})` }}
                                    />
                                    <div class="styleguide-color-swatch__info">
                                        <span class="styleguide-color-swatch__label">{color.label}</span>
                                        <code class="styleguide-color-swatch__var">{color.var}</code>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                ))}
            </div>
        );
    }
});
