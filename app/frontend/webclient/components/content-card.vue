<template>
  <component :is="as" ref="cardRootRef" class="ctv-content-card" @mouseenter="setHover(true)"
    @mouseleave="setHover(false)" @focusin="setHover(true)" @focusout="setHover(false)">
    <RouterLink :to="contentLink" class="ctv-content-card__link recyclerview-card-article aspect-video">
      <div class="ctv-content-card__image recyclerview-card-article__image aspect-video">
        <img v-if="card.banner" :src="card.banner" :alt="card.title || 'Contenido de CinelarTV'" loading="lazy" />
        <div v-else class="ctv-content-card__placeholder">Sin imagen disponible</div>
      </div>

      <div class="ctv-content-card__overlay recyclerview-card-article__overlay"
        :class="showProgress ? 'with-progress' : ''">
        <div class="recyclerview-card-article__premium-badge" v-if="card.premium">
          <CIcon icon="lock" :size="12" />
          <span>PREMIUM</span>
        </div>

        <div class="recyclerview-card-article__title">
          {{ card.title || 'Sin titulo' }}
        </div>

        <div class="recyclerview-card-article__progress" v-if="showProgress">
          <div class="recyclerview-card-article__progress__bar">
            <div class="recyclerview-card-article__progress__bar__progress" :style="{ width: `${progressPercent}%` }" />
          </div>
        </div>
      </div>

      <img v-if="card.banner" :src="card.banner" class="blurred-shadow" :alt="card.title || 'Contenido de CinelarTV'" />
    </RouterLink>

    <teleport to="body">
      <div class="ctv-content-card__expanded ctv-content-card__expanded--floating expanded-info"
        v-if="showExpandedPanel" :style="expandedPanelStyle">
        <p class="expanded-info__title">{{ card.title || 'Sin titulo' }}</p>
        <p class="expanded-info__description">{{ card.description }}</p>
      </div>
    </teleport>
  </component>
</template>

<script setup>
import { computed, onUnmounted, ref } from 'vue'
import CIcon from './c-icon.vue'

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
  as: {
    type: String,
    default: 'div',
  },
})

const isHovering = ref(false)
const cardRootRef = ref(null)
const expandedPanelStyle = ref({
  top: '0px',
  left: '0px',
  width: '0px',
})

const card = computed(() => props.data || {})

const contentLink = computed(() => {
  if (card.value.id === undefined || card.value.id === null) return '/'
  return `/contents/${card.value.id}`
})

const showProgress = computed(() => {
  const progress = Number(card.value.progress)
  const duration = Number(card.value.duration)
  return Number.isFinite(progress) && Number.isFinite(duration) && duration > 0 && progress > 0
})

const progressPercent = computed(() => {
  if (!showProgress.value) return 0
  const progress = Number(card.value.progress)
  const duration = Number(card.value.duration)
  return Math.min(100, Math.max(0, (progress / duration) * 100))
})

const showExpandedPanel = computed(() => {
  return isHovering.value && !!card.value.description
})

const updateExpandedPanelPosition = () => {
  if (!showExpandedPanel.value || !cardRootRef.value) return

  const rect = cardRootRef.value.getBoundingClientRect()
  const viewportWidth = window.innerWidth
  const panelMaxWidth = 340
  const panelWidth = Math.min(panelMaxWidth, Math.max(rect.width, 220), viewportWidth - 16)
  const panelTop = rect.bottom + 8
  const maxLeft = viewportWidth - panelWidth - 8
  const centeredLeft = rect.left + (rect.width - panelWidth) / 2
  const panelLeft = Math.min(Math.max(8, centeredLeft), Math.max(8, maxLeft))

  expandedPanelStyle.value = {
    top: `${Math.round(panelTop)}px`,
    left: `${Math.round(panelLeft)}px`,
    width: `${Math.round(panelWidth)}px`,
  }
}

const bindExpandedListeners = () => {
  window.addEventListener('scroll', updateExpandedPanelPosition, true)
  window.addEventListener('resize', updateExpandedPanelPosition)
}

const unbindExpandedListeners = () => {
  window.removeEventListener('scroll', updateExpandedPanelPosition, true)
  window.removeEventListener('resize', updateExpandedPanelPosition)
}

const setHover = (value) => {
  if (isHovering.value === value) return

  isHovering.value = value

  if (value) {
    requestAnimationFrame(updateExpandedPanelPosition)
    bindExpandedListeners()
    return
  }

  unbindExpandedListeners()
}

onUnmounted(() => {
  unbindExpandedListeners()
})
</script>

<style scoped>
.ctv-content-card {
  width: 100%;
  display: block;
  position: relative;
  isolation: isolate;
}

.ctv-content-card__link {
  position: relative;
  display: block;
  width: 100%;
  border-radius: 10px;
  overflow: hidden;
  border: 1px solid color-mix(in srgb, var(--c-body-text-color, #ffffff) 10%, transparent 90%);
  transition: transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
}

.ctv-content-card__link:hover,
.ctv-content-card__link:focus-visible {
  transform: translateY(-2px) scale(1.01);
  border-color: color-mix(in srgb, var(--c-primary-300, #42c0ff) 55%, transparent 45%);
  box-shadow: 0 12px 26px rgba(0, 0, 0, 0.35);
}

.ctv-content-card__link:focus-visible {
  outline: 2px solid color-mix(in srgb, var(--c-primary-300, #42c0ff) 40%, transparent 60%);
  outline-offset: 2px;
}

.ctv-content-card__image {
  position: relative;
  background: color-mix(in srgb, var(--c-background-color, #11141a) 80%, #ffffff 20%);
}

.ctv-content-card__image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.ctv-content-card__placeholder {
  width: 100%;
  aspect-ratio: 16 / 9;
  display: grid;
  place-items: center;
  color: color-mix(in srgb, var(--c-body-text-color, #ffffff) 70%, transparent 30%);
  font-size: 0.78rem;
  padding: 10px;
  text-align: center;
}

.ctv-content-card__overlay {
  pointer-events: none;
}

.ctv-content-card__expanded {
  border: 1px solid color-mix(in srgb, var(--c-body-text-color, #ffffff) 10%, transparent 90%);
  background: color-mix(in srgb, var(--c-background-color, #101218) 82%, #ffffff 18%);
  border-radius: 10px;
  padding: 10px;
  animation: card-expanded-in 0.2s ease;
}

.ctv-content-card__expanded--floating {
  position: fixed;
  z-index: 1200;
  box-shadow: 0 14px 30px rgba(0, 0, 0, 0.45);
  pointer-events: none;
  backdrop-filter: blur(3px);
}

.expanded-info__title {
  margin: 0;
  color: var(--c-body-text-color, #ffffff);
  font-size: 0.85rem;
  font-weight: 700;
}

.expanded-info__description {
  margin: 6px 0 0;
  color: color-mix(in srgb, var(--c-body-text-color, #ffffff) 70%, transparent 30%);
  font-size: 0.78rem;
  line-height: 1.45;
  line-clamp: 2;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

@media (max-width: 768px) {
  .ctv-content-card__expanded {
    display: none;
  }
}

@keyframes card-expanded-in {
  from {
    opacity: 0;
    transform: translateY(4px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
