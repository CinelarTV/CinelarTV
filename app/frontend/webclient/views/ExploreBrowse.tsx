import { defineComponent, ref, computed, onMounted, watch } from 'vue';
import { useHead } from 'unhead';
import { toast } from 'vue-sonner';
import { ajax } from '../lib/Ajax';
import { useSiteSettings } from '../app/services/site-settings';
import { PiniaStore } from '../app/lib/Pinia';

interface ContentItem {
    id: string;
    title: string;
    description?: string;
    banner?: string;
    content_type: string;
    year?: number;
}

interface Category {
    id: number;
    name: string;
}

export default defineComponent({
    name: 'ExploreBrowse',
    setup() {
        const { siteSettings } = useSiteSettings(PiniaStore);

        const contents = ref<ContentItem[]>([]);
        const categories = ref<Category[]>([]);
        const loading = ref(true);
        const selectedCategory = ref<number | null>(null);
        const selectedType = ref<string>('');
        const selectedSort = ref<string>('trending');

        const sortOptions = computed(() => [
            { value: 'trending', label: 'Tendencia' },
            { value: 'newest', label: 'Más recientes' },
            { value: 'most_liked', label: 'Más gustados' },
        ]);

        const typeOptions = computed(() => [
            { value: '', label: 'Todo' },
            { value: 'MOVIE', label: 'Películas' },
            { value: 'TVSHOW', label: 'Series' },
        ]);

        const filteredContents = computed(() => {
            let result = contents.value;

            if (selectedCategory.value) {
                // Client-side filtering is not ideal, but we fetch from API with filters
            }

            return result;
        });

        const groupedByCategory = computed(() => {
            if (!selectedCategory.value && !selectedType.value) {
                // Group by category when no specific filter
                const grouped = new Map<string, ContentItem[]>();
                contents.value.forEach(item => {
                    // For now, just show all in one row since we don't have category info in the response
                    if (!grouped.has('all')) {
                        grouped.set('all', []);
                    }
                    grouped.get('all')!.push(item);
                });
                return grouped;
            }
            const grouped = new Map<string, ContentItem[]>();
            grouped.set('filtered', contents.value);
            return grouped;
        });

        useHead({
            title: 'Explorar',
        });

        const loadContent = async () => {
            try {
                loading.value = true;
                const params = new URLSearchParams();
                if (selectedCategory.value) params.append('category_id', String(selectedCategory.value));
                if (selectedType.value) params.append('content_type', selectedType.value);
                if (selectedSort.value) params.append('sort', selectedSort.value);

                const response = await ajax.get(`/explore/browse.json?${params.toString()}`);
                contents.value = response.data.contents || [];
                if (response.data.categories) {
                    categories.value = response.data.categories;
                }
            } catch (error) {
                console.error('Error loading explore data:', error);
                toast.error('Error al cargar el contenido');
            } finally {
                loading.value = false;
            }
        };

        onMounted(() => {
            loadContent();
        });

        watch([selectedCategory, selectedType, selectedSort], () => {
            loadContent();
        });

        return {
            contents,
            categories,
            loading,
            selectedCategory,
            selectedType,
            selectedSort,
            sortOptions,
            typeOptions,
            groupedByCategory,
            siteSettings,
        };
    },
    render() {
        return (
            <div class="min-h-screen explore-browse">
                {/* Header */}
                <div class="px-4 sm:px-6 md:px-8 lg:px-12 pt-6 pb-4">
                    <h1 class="text-2xl sm:text-3xl font-semibold text-white mb-6">
                        Explorar
                    </h1>

                    {/* Filters */}
                    <div class="flex flex-wrap gap-3 mb-6">
                        {/* Category chips */}
                        <div class="flex flex-wrap gap-2">
                            <button
                                onClick={() => { this.selectedCategory = null; }}
                                class={`px-3 py-1.5 rounded-full text-sm font-medium transition-all duration-200 ${
                                    this.selectedCategory === null
                                        ? 'bg-white text-black'
                                        : 'bg-white/10 text-white/70 hover:bg-white/20 hover:text-white'
                                }`}
                            >
                                Todos
                            </button>
                            {this.categories.map((cat: any) => (
                                <button
                                    key={cat.id}
                                    onClick={() => { this.selectedCategory = cat.id; }}
                                    class={`px-3 py-1.5 rounded-full text-sm font-medium transition-all duration-200 ${
                                        this.selectedCategory === cat.id
                                            ? 'bg-white text-black'
                                            : 'bg-white/10 text-white/70 hover:bg-white/20 hover:text-white'
                                    }`}
                                >
                                    {cat.name}
                                </button>
                            ))}
                        </div>

                        {/* Type filter */}
                        <div class="flex gap-2 ml-auto">
                            {this.typeOptions.map((opt: any) => (
                                <button
                                    key={opt.value}
                                    onClick={() => { this.selectedType = opt.value; }}
                                    class={`px-3 py-1.5 rounded-full text-sm font-medium transition-all duration-200 ${
                                        this.selectedType === opt.value
                                            ? 'bg-white text-black'
                                            : 'bg-white/10 text-white/70 hover:bg-white/20 hover:text-white'
                                    }`}
                                >
                                    {opt.label}
                                </button>
                            ))}
                        </div>

                        {/* Sort */}
                        <div class="flex gap-2">
                            {this.sortOptions.map((opt: any) => (
                                <button
                                    key={opt.value}
                                    onClick={() => { this.selectedSort = opt.value; }}
                                    class={`px-3 py-1.5 rounded-full text-sm font-medium transition-all duration-200 ${
                                        this.selectedSort === opt.value
                                            ? 'bg-[#00A8E1] text-white'
                                            : 'bg-white/10 text-white/70 hover:bg-white/20 hover:text-white'
                                    }`}
                                >
                                    {opt.label}
                                </button>
                            ))}
                        </div>
                    </div>
                </div>

                {/* Loading */}
                {this.loading && (
                    <div class="flex items-center justify-center py-20">
                        <div class="flex flex-col items-center gap-3">
                            <div class="animate-spin rounded-full h-10 w-10 border-2 border-white/30 border-t-[#00A8E1]"></div>
                            <p class="text-white/60 text-sm">Cargando...</p>
                        </div>
                    </div>
                )}

                {/* Content grid */}
                {!this.loading && (
                    <div class="px-4 sm:px-6 md:px-8 lg:px-12 pb-12">
                        {this.contents.length > 0 ? (
                            <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3 md:gap-4">
                                {this.contents.map((item: any) => (
                                    <a
                                        key={item.id}
                                        href={`/contents/${item.id}`}
                                        class="group relative aspect-video rounded-lg overflow-hidden bg-white/5 border border-white/[0.06] hover:scale-[1.03] hover:border-white/20 hover:shadow-[0_8px_30px_rgba(0,0,0,0.5)] transition-all duration-200"
                                    >
                                        {item.banner ? (
                                            <img
                                                src={item.banner}
                                                alt={item.title}
                                                class="w-full h-full object-cover"
                                                loading="lazy"
                                            />
                                        ) : (
                                            <div class="w-full h-full flex items-center justify-center bg-white/10">
                                                <span class="text-white/40 text-xs">Sin imagen</span>
                                            </div>
                                        )}

                                        {/* Overlay */}
                                        <div class="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex flex-col justify-end p-3">
                                            <p class="text-sm font-medium text-white leading-tight line-clamp-2">
                                                {item.title}
                                            </p>
                                            <div class="flex items-center gap-2 mt-1">
                                                {item.year && (
                                                    <span class="text-[11px] text-white/60">{item.year}</span>
                                                )}
                                                <span class="text-[10px] px-1.5 py-0.5 rounded bg-white/20 text-white/80">
                                                    {item.content_type === 'MOVIE' ? 'Película' : 'Serie'}
                                                </span>
                                            </div>
                                        </div>
                                    </a>
                                ))}
                            </div>
                        ) : (
                            <div class="flex items-center justify-center py-20">
                                <div class="text-center text-white/60">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" class="w-12 h-12 mx-auto mb-4 opacity-50">
                                        <circle cx="11" cy="11" r="8" />
                                        <path d="m21 21-4.3-4.3" />
                                    </svg>
                                    <p class="text-lg font-medium mb-1">No se encontraron resultados</p>
                                    <p class="text-sm">Intenta con otros filtros.</p>
                                </div>
                            </div>
                        )}
                    </div>
                )}
            </div>
        );
    },
});
