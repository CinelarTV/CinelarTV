import { defineComponent, ref, PropType } from 'vue'
import CIcon from "../c-icon.vue"

interface Episode {
    id: string
    title: string
    description: string
    thumbnail: string
    duration: number | null
    position: number,
    continue_watching?: {
        progress: number
        duration: number
    }
}

interface Season {
    id: string
    title?: string
    episodes: { data: Episode }[]
}

export default defineComponent({
    name: 'EpisodesList',
    props: {
        seasons: {
            type: Array as PropType<Season[]>,
            required: true,
        },
        activeSeason: {
            type: String,
            required: true,
        },
    },
    emits: ['update:activeSeason', 'playEpisode'],
    setup(props, { emit }) {
        const scrollPosition = ref(0)
        const episodesContainer = ref<HTMLElement>()

        const playEpisode = (episodeId: string) => {
            emit('playEpisode', episodeId)
        }

        const scrollLeft = () => {
            const container = episodesContainer.value
            if (container) {
                const newPosition = Math.max(0, scrollPosition.value - 350)
                container.scrollTo({ left: newPosition, behavior: "smooth" })
                scrollPosition.value = newPosition
            }
        }

        const scrollRight = () => {
            const container = episodesContainer.value
            if (container) {
                const maxScroll = container.scrollWidth - container.clientWidth
                const newPosition = Math.min(maxScroll, scrollPosition.value + 350)
                container.scrollTo({ left: newPosition, behavior: "smooth" })
                scrollPosition.value = newPosition
            }
        }

        const handleScroll = (e: Event) => {
            const target = e.currentTarget as HTMLElement
            scrollPosition.value = target.scrollLeft
        }

        const handleSeasonChange = (e: Event) => {
            const value = (e.target as HTMLSelectElement).value
            emit('update:activeSeason', value)
        }

        return () => (
            <div class="text-white">
                {/* Header Section */}
                <div class="px-2 sm:px-4 md:px-8 py-8">
                    <h1 class="text-2xl font-bold mb-6">Episodios</h1>

                    {/* Season Selector */}
                    <div class="mb-8">
                        <select
                            value={props.activeSeason}
                            onChange={handleSeasonChange}
                            class="bg-[#2a2a2a] border border-[#404040] rounded px-4 py-2 text-white focus:outline-none focus:border-white"
                        >
                            {props.seasons?.map((season) => (
                                <option key={season.id} value={season.id}>
                                    {season.title || `Temporada ${season.id}`}
                                </option>
                            ))}
                        </select>
                    </div>

                    {/* Episodes List */}
                    <div class="episodes-list">
                        {props.seasons?.map((season) => (
                            <div
                                key={season.id}
                                style={{ display: String(season.id) === props.activeSeason ? "block" : "none" }}
                            >
                                {season.episodes.length === 0 ? (
                                    <p class="text-center text-gray-400">No hay episodios disponibles.</p>
                                ) : (
                                    <div class="relative group">
                                        {/* Scroll Buttons (ocultos en móvil) */}
                                        <button
                                            onClick={scrollLeft}
                                            class="hidden sm:block absolute left-0 top-1/2 -translate-y-1/2 z-10 bg-black/50 hover:bg-black/70 rounded-full p-2 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                                            style={{ marginLeft: "-20px" }}
                                        >
                                            <CIcon icon="chevron-left" class="w-6 h-6" />
                                        </button>

                                        <button
                                            onClick={scrollRight}
                                            class="hidden sm:block absolute right-0 top-1/2 -translate-y-1/2 z-10 bg-black/50 hover:bg-black/70 rounded-full p-2 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                                            style={{ marginRight: "-20px" }}
                                        >
                                            <CIcon icon="chevron-right" class="w-6 h-6" />
                                        </button>

                                        {/* Episodes Container */}
                                        <div
                                            ref={episodesContainer}
                                            class="episodes-scroll-container flex gap-2 overflow-x-auto scrollbar-hide pb-4 snap-x snap-mandatory"
                                            style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
                                            onScroll={handleScroll}
                                        >
                                            {season.episodes.map(({ data: episode }, index) => (
                                                <div
                                                    key={episode.id}
                                                    class="episode-card flex-shrink-0 w-[90vw] sm:w-[350px] max-w-[350px] min-w-[260px] cursor-pointer group/card snap-center"
                                                    onClick={() => playEpisode(episode.id)}
                                                >
                                                    {/* Episode Thumbnail */}
                                                    <div class="relative overflow-hidden rounded-lg mb-3">
                                                        <img
                                                            src={episode.thumbnail || "/placeholder.svg"}
                                                            alt={episode.title}
                                                            class="w-full h-[40vw] sm:h-[200px] object-cover transition-transform duration-300 group-hover/card:scale-105 min-h-[120px] max-h-[200px]"
                                                        />

                                                        {/* Overlay */}
                                                        <div class="absolute inset-0 bg-black/0 group-hover/card:bg-black/30 transition-colors duration-300" />

                                                        {/* Play Button */}
                                                        <div class="absolute inset-0 flex items-center justify-center opacity-0 group-hover/card:opacity-100 transition-opacity duration-300">
                                                            <div class="bg-white/20 backdrop-blur-sm rounded-full p-3">
                                                                <CIcon icon="play" class="w-8 h-8 text-white" />
                                                            </div>
                                                        </div>

                                                        {(typeof episode.duration === 'number' && !isNaN(episode.duration)) && (
                                                            <div class="absolute bottom-2 right-3 bg-black/70 px-2 py-1 rounded text-white text-sm">
                                                                {episode.duration}
                                                            </div>
                                                        )}


                                                        {/* Barra de progreso de continue watching */}
                                                        {episode.continue_watching && episode.continue_watching.duration > 0 && (
                                                            <div class="absolute left-0 right-0 bottom-0 h-2 bg-black/40">
                                                                <div
                                                                    class="h-2 bg-blue-500 transition-all"
                                                                    style={{ width: `${Math.min(100, Math.round((episode.continue_watching.progress / episode.continue_watching.duration) * 100))}%` }}
                                                                />
                                                            </div>
                                                        )}
                                                    </div>

                                                    {/* Episode Info */}
                                                    <div class="px-1">
                                                        <h3 class="text-white font-semibold text-lg mb-2 line-clamp-1">
                                                            {(typeof episode.position === 'number' ? episode.position + 1 : index + 1)}. {episode.title}
                                                        </h3>
                                                        <p class="text-gray-300 text-sm line-clamp-3 leading-relaxed">
                                                            {episode.description}
                                                        </p>
                                                    </div>


                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>
                </div>

                <style>
                    {`
            .episodes-scroll-container::-webkit-scrollbar {
              display: none;
            }
            .episodes-scroll-container {
              scroll-snap-type: x mandatory;
              -webkit-overflow-scrolling: touch;
            }
            .episode-card {
              scroll-snap-align: center;
            }
            @media (max-width: 640px) {
              .episode-card {
                width: 90vw !important;
                min-width: 260px !important;
                max-width: 350px !important;
              }
              .episodes-scroll-container {
                gap: 0.5rem;
                padding-bottom: 1rem;
              }
            }
            .line-clamp-1 {
              display: -webkit-box;
              -webkit-line-clamp: 1;
              -webkit-box-orient: vertical;
              overflow: hidden;
            }
            .line-clamp-3 {
              display: -webkit-box;
              -webkit-line-clamp: 3;
              -webkit-box-orient: vertical;
              overflow: hidden;
            }
          `}
                </style>
            </div>
        )
    }
})