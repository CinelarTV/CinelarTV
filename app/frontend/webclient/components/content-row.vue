<script lang="ts">
import { defineComponent, ref, computed, onMounted, onUnmounted, PropType, getCurrentInstance } from 'vue';
import { RouterLink } from 'vue-router';
import ExpandableContentCard from './ExpandableContentCard.tsx';

interface ContentItem {
    id: number | string;
    title: string;
    description?: string;
    banner: string;
    poster?: string;
    year?: number;
    rating?: string;
    genres?: string[];
    duration?: number;
    progress?: number;
    isPrime?: boolean;
    isNew?: boolean;
}

declare module 'vue' {
    interface ComponentCustomProperties {
        $isMobile: () => boolean;
    }
}

export default defineComponent({
    name: 'ContentRow',
    components: {
        ExpandableContentCard,
    },
    props: {
        title: {
            type: String,
            required: true,
        },
        items: {
            type: Array as PropType<ContentItem[]>,
            required: true,
        },
        itemType: {
            type: String as PropType<'landscape' | 'portrait'>,
            default: 'landscape',
        },
        showSeeAll: {
            type: Boolean,
            default: true,
        },
        expandable: {
            type: Boolean,
            default: true,
        },
    },
    emits: ['see-all'],
    setup(props, { emit }) {
        const scrollContainer = ref<HTMLElement | null>(null);
        const canScrollLeft = ref(false);
        const canScrollRight = ref(false);
        const expandedItemId = ref<number | string | null>(null);
        const instance = getCurrentInstance();

        const isMobile = () => instance?.proxy?.$isMobile?.() ?? window.innerWidth < 768;

        const handleCardExpand = (itemId: number | string) => {
            expandedItemId.value = itemId;
        };

        const handleCardClose = (itemId: number | string) => {
            if (expandedItemId.value === itemId) {
                expandedItemId.value = null;
            }
        };

        const cardClass = computed(() => {
            if (props.itemType === 'portrait') {
                return 'w-[100px] sm:w-[120px] md:w-[140px] lg:w-[160px]';
            }
            return 'w-[180px] sm:w-[220px] md:w-[260px] lg:w-[300px]';
        });

        const aspectClass = computed(() =>
            props.itemType === 'portrait' ? 'aspect-[2/3]' : 'aspect-video'
        );

        const checkScrollability = () => {
            const el = scrollContainer.value;
            if (!el) return;
            canScrollLeft.value = el.scrollLeft > 10;
            canScrollRight.value = el.scrollLeft < el.scrollWidth - el.clientWidth - 10;
        };

        const scroll = (direction: 'left' | 'right') => {
            const el = scrollContainer.value;
            if (!el) return;
            const amount = el.clientWidth * 0.75;
            el.scrollBy({
                left: direction === 'left' ? -amount : amount,
                behavior: 'smooth',
            });
        };

        const progressPercent = (item: ContentItem) => {
            if (!item.progress || !item.duration) return 0;
            return Math.min(100, Math.round((item.progress / item.duration) * 100));
        };

        onMounted(() => {
            checkScrollability();
            window.addEventListener('resize', checkScrollability);
        });

        onUnmounted(() => {
            window.removeEventListener('resize', checkScrollability);
        });

        return {
            scrollContainer,
            canScrollLeft,
            canScrollRight,
            cardClass,
            aspectClass,
            isMobile,
            checkScrollability,
            scroll,
            progressPercent,
            emit,
            expandable: props.expandable,
            expandedItemId,
            handleCardExpand,
            handleCardClose,
        };
    },
});
</script>

<template>
    <div v-if="items.length" class="content-row mb-8 md:mb-12">

        <!-- Row header -->
        <div class="row-header flex items-center justify-between px-4 sm:px-6 md:px-8 lg:px-12 mb-3 md:mb-4">
            <h3 class="text-base sm:text-lg md:text-xl font-medium text-white tracking-tight">
                {{ title }}
            </h3>
            <button v-if="showSeeAll"
                class="see-all-btn flex items-center gap-1 text-xs text-white/50 hover:text-white/90 transition-colors duration-150"
                @click="emit('see-all')">
                Ver todo
                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="9 18 15 12 9 6" />
                </svg>
            </button>
        </div>

        <!-- Scroll container wrapper -->
        <div class="scroll-outer relative group/row">

            <!-- Left arrow -->
            <Transition name="fade-arrow">
                <button v-if="canScrollLeft && !isMobile()"
                    class="arrow-btn absolute left-0 top-0 bottom-3 z-20 w-10 md:w-12 flex items-center justify-center opacity-0 group-hover/row:opacity-100 transition-opacity duration-200"
                    aria-label="Anterior" @click="scroll('left')">
                    <span
                        class="arrow-circle w-7 h-7 md:w-8 md:h-8 rounded-full bg-black/70 border border-white/20 flex items-center justify-center hover:bg-black/90 hover:border-white/40 hover:scale-105 active:scale-95 transition-all duration-150">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none"
                            stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="15 18 9 12 15 6" />
                        </svg>
                    </span>
                </button>
            </Transition>

            <!-- Scroll area -->
            <div ref="scrollContainer"
                class="flex overflow-x-auto gap-2 md:gap-3 px-4 sm:px-6 md:px-8 lg:px-12 py-3 -my-3 scroll-smooth snap-x snap-mandatory"
                :class="{ 'expandable-row-container': expandable }"
                style="scrollbar-width: none; -ms-overflow-style: none;" @scroll="checkScrollability">
                <!-- Expandable cards -->
                <template v-if="expandable">
                    <ExpandableContentCard
                        v-for="item in items"
                        :key="item.id"
                        :item="item"
                        :item-type="itemType"
                        :expanded="expandedItemId === item.id"
                        @expand="handleCardExpand"
                        @close="handleCardClose"
                    />
                </template>

                <!-- Fallback: simple cards when expandable is disabled -->
                <template v-else>
                    <RouterLink v-for="item in items" :key="`simple-${item.id}`" :to="`/contents/${item.id}`"
                        :class="['flex-shrink-0 snap-start group/card', cardClass, aspectClass]">
                        <!-- Card -->
                        <div
                            class="relative w-full h-full rounded-lg overflow-hidden bg-white/5 border border-white/[0.06] transition-all duration-200 ease-out group-hover/card:scale-[1.04] group-hover/card:border-white/20 group-hover/card:shadow-[0_8px_30px_rgba(0,0,0,0.5)]">

                            <!-- Thumbnail -->
                            <img :src="item.banner" :alt="item.title" class="w-full h-full object-cover" loading="lazy" />

                            <!-- Hover overlay -->
                            <div
                                class="overlay absolute inset-0 bg-gradient-to-t from-black/90 via-black/10 to-transparent opacity-0 group-hover/card:opacity-100 transition-opacity duration-200 flex flex-col justify-end p-3">
                                <p class="text-[11px] font-medium text-white leading-tight line-clamp-2">
                                    {{ item.title }}
                                </p>
                                <p v-if="item.year || item.rating" class="text-[10px] text-white/60 mt-1">
                                    <span v-if="item.year">{{ item.year }}</span>
                                    <span v-if="item.year && item.rating"> · </span>
                                    <span v-if="item.rating">{{ item.rating }}</span>
                                    <span v-if="item.progress && item.duration"> · {{ progressPercent(item) }}% visto</span>
                                </p>
                            </div>

                            <!-- Progress bar -->
                            <div v-if="item.progress && item.duration"
                                class="absolute bottom-0 left-0 right-0 h-[2px] bg-white/15">
                                <div class="h-full bg-[#0095d9]" :style="{ width: `${progressPercent(item)}%` }" />
                            </div>

                            <!-- Badges -->
                            <div class="absolute top-2 left-2 flex gap-1">
                                <!-- NEW badge -->
                                <span v-if="item.isNew"
                                    class="text-[9px] font-medium px-1.5 py-0.5 rounded bg-white/15 text-white border border-white/25 backdrop-blur-sm leading-none">
                                    NUEVO
                                </span>
                                <!-- PRIME badge -->
                                <span v-else-if="item.isPrime !== false"
                                    class="text-[9px] font-medium px-1.5 py-0.5 rounded bg-[#0095d9] text-white leading-none">
                                    PRIME
                                </span>
                            </div>

                        </div>
                    </RouterLink>
                </template>
            </div>

            <Transition name="fade-arrow">
                <button v-if="canScrollRight && !isMobile()"
                    class="arrow-btn absolute right-0 top-0 bottom-3 z-20 w-10 md:w-12 flex items-center justify-center opacity-0 group-hover/row:opacity-100 transition-opacity duration-200"
                    aria-label="Siguiente" @click="scroll('right')">
                    <span
                        class="arrow-circle w-7 h-7 md:w-8 md:h-8 rounded-full bg-black/70 border border-white/20 flex items-center justify-center hover:bg-black/90 hover:border-white/40 hover:scale-105 active:scale-95 transition-all duration-150">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none"
                            stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="9 18 15 12 9 6" />
                        </svg>
                    </span>
                </button>
            </Transition>

        </div>
    </div>
</template>

<style scoped>
/* Hide webkit scrollbar */
.scroll-outer ::-webkit-scrollbar {
    display: none;
}

/* Arrow fade transition */
.fade-arrow-enter-active,
.fade-arrow-leave-active {
    transition: opacity 0.15s ease;
}

.fade-arrow-enter-from,
.fade-arrow-leave-to {
    opacity: 0;
}

/* Left/right arrow gradient masks */
.arrow-btn:first-of-type {
    background: linear-gradient(to right, rgba(0, 0, 0, 0.6), transparent);
}

.arrow-btn:last-of-type {
    background: linear-gradient(to left, rgba(0, 0, 0, 0.6), transparent);
}
</style>