import { defineComponent } from 'vue';
import ContentRatingBadge from '@/components/ContentRatingBadge';

const mockRatings = [
    {
        code: 'ALL',
        system: 'custom',
        name: 'Para todos',
        description: 'Apto para todas las edades',
        min_age: 0,
        color: '#4ade80'
    },
    {
        code: 'ALL13',
        system: 'custom',
        name: '13+',
        description: 'No recomendado menores de 13',
        min_age: 13,
        color: '#facc15'
    },
    {
        code: 'ALL16',
        system: 'custom',
        name: '16+',
        description: 'No recomendado menores de 16',
        min_age: 16,
        color: '#fb923c'
    },
    {
        code: 'ALL18',
        system: 'custom',
        name: '18+',
        description: 'Solo adultos',
        min_age: 18,
        color: '#f87171'
    }
];

const mockDescriptors = [
    { key: 'language', name: 'Lenguaje malsonante', category: 'lenguaje', severity_level: 1 },
    { key: 'violence', name: 'Escenas de violencia', category: 'violencia', severity_level: 2 },
    { key: 'sexual_scenes', name: 'Escenas sexuales', category: 'sexual', severity_level: 3 }
];

const mockDescriptorsAll = [
    { key: 'language', name: 'Lenguaje malsonante', category: 'lenguaje', severity_level: 1 },
    { key: 'violence', name: 'Escenas de violencia', category: 'violencia', severity_level: 2 },
    { key: 'alcohol_drugs', name: 'Consumo de alcohol o drogas', category: 'sustancias', severity_level: 2 },
    { key: 'fear', name: 'Miedo o contenido perturbador', category: 'miedo', severity_level: 2 }
];

export default defineComponent({
    name: 'ContentRatingBadgeSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">ContentRatingBadge</h1>
                <p class="styleguide-section__description">
                    Badge de clasificación por edad y descriptores de contenido. Se usa en la ficha del contenido
                    y como overlay en el reproductor de video.
                </p>

                {/* Compact mode (player overlay) */}
                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Compact (Player Overlay)</h2>
                    <p class="styleguide-subsection__description">
                        Versión compacta para mostrar en el reproductor. Aparece con fade-out automático.
                    </p>
                    <div class="flex flex-wrap gap-4">
                        {mockRatings.map(rating => (
                            <div key={rating.code} class="bg-black/40 rounded-lg p-4 min-w-[120px]">
                                <ContentRatingBadge
                                    rating={rating}
                                    descriptors={[]}
                                    compact={true}
                                    position="top-left"
                                />
                            </div>
                        ))}
                    </div>
                </div>

                {/* Compact with descriptors */}
                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Compact con Descriptores</h2>
                    <div class="flex flex-wrap gap-4">
                        <div class="bg-black/40 rounded-lg p-4 min-w-[200px]">
                            <ContentRatingBadge
                                rating={mockRatings[2]}
                                descriptors={mockDescriptors}
                                compact={true}
                                position="top-left"
                            />
                        </div>
                    </div>
                </div>

                {/* Full mode (content detail) */}
                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Full (Content Detail)</h2>
                    <p class="styleguide-subsection__description">
                        Versión completa con nombre del rating, descripción y chips de descriptores.
                    </p>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        {mockRatings.map(rating => (
                            <div key={rating.code} class="bg-white/5 rounded-lg p-4">
                                <ContentRatingBadge
                                    rating={rating}
                                    descriptors={mockDescriptorsAll.slice(0, rating.min_age >= 16 ? 4 : 2)}
                                    compact={false}
                                    position="top-left"
                                />
                            </div>
                        ))}
                    </div>
                </div>

                {/* All Descriptors */}
                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Descriptores de Contenido</h2>
                    <p class="styleguide-subsection__description">
                        Los descriptores se agrupan por categoría y nivel de severidad.
                    </p>
                    <div class="space-y-3">
                        {['violencia', 'lenguaje', 'sexual', 'sustancias', 'miedo'].map(cat => (
                            <div key={cat} class="flex items-center gap-3">
                                <span class="text-sm text-white/60 w-24 capitalize">{cat}</span>
                                <div class="flex gap-2">
                                    {mockDescriptorsAll.filter(d => d.category === cat).map(d => (
                                        <span key={d.key} class="text-xs px-2 py-1 rounded-full bg-white/10 text-white/80">
                                            {d.name}
                                        </span>
                                    ))}
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        );
    }
});
