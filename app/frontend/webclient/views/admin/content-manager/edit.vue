<template>
  <div v-if="loading" class="edit-page__loader">
    <div class="edit-page__loader-spinner" />
    <p class="edit-page__loader-text">Cargando contenido…</p>
  </div>

  <div v-else class="edit-page">
    <!-- ── Hero header ─────────────────────────────────────────────────────── -->
    <div
      class="edit-page__hero"
      :style="content.banner ? `--hero-backdrop: url(${content.banner})` : ''"
    >
      <div class="edit-page__hero-backdrop" />
      <div class="edit-page__hero-inner">
        <button class="edit-page__back-btn" @click="router.back()">
          <CIcon icon="arrowLeft" :size="18" />
        </button>

        <div class="edit-page__hero-meta">
          <div class="edit-page__hero-badges">
            <span class="edit-page__type-chip">
              {{ contentTypeLabel }}
            </span>
            <span
              v-if="editedData.available"
              class="edit-page__status-chip edit-page__status-chip--available"
            >
              <CIcon icon="eye" :size="11" />
              Publicado
            </span>
            <span v-else class="edit-page__status-chip edit-page__status-chip--hidden">
              <CIcon icon="eyeOff" :size="11" />
              Oculto
            </span>
            <span v-if="editedData.premium" class="edit-page__status-chip edit-page__status-chip--premium">
              <CIcon icon="sparkles" :size="11" />
              Premium
            </span>
          </div>

          <h1 class="edit-page__hero-title">
            {{ editedData.title || content.title || 'Sin título' }}
          </h1>

          <p v-if="scheduledCountdown" class="edit-page__scheduled-hint">
            <CIcon icon="clock" :size="13" />
            Estreno {{ scheduledCountdown }}
          </p>
        </div>

        <!-- Quick save -->
        <div class="edit-page__hero-actions">
          <CButton
            variant="primary"
            icon="check"
            :loading="loadingButton"
            @click="saveContent"
          >
            Guardar
          </CButton>
          <CButton
            variant="danger"
            icon="trash2"
            @click="deleteContent"
          />
        </div>
      </div>
    </div>

    <!-- ── Body ───────────────────────────────────────────────────────────── -->
    <div class="edit-page__body">
      <!-- Left rail ─ tabs navigation -->
      <nav class="edit-page__nav">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          class="edit-page__nav-item"
          :class="{ 'edit-page__nav-item--active': activeTab === tab.key }"
          @click="activeTab = tab.key"
        >
          <CIcon :icon="tab.icon" :size="16" />
          <span>{{ tab.label }}</span>
        </button>
      </nav>

      <!-- Main content area -->
      <div class="edit-page__main">

        <!-- ══ TAB: General ══════════════════════════════════════════════════ -->
        <section v-show="activeTab === 'general'" class="edit-page__section-grid">

          <!-- Basic info -->
          <div class="edit-card">
            <h2 class="edit-card__title">
              <CIcon icon="fileText" :size="16" />
              Información básica
            </h2>

            <div class="edit-card__fields">
              <CFormRow label="Título">
                <c-input v-model="editedData.title" placeholder="Título del contenido" />
              </CFormRow>

              <CFormRow label="Tipo">
                <c-select :options="contentTypes" v-model="editedData.content_type" />
              </CFormRow>

              <CFormRow label="Descripción">
                <c-textarea v-model="editedData.description" placeholder="Sinopsis…" :rows="4" />
              </CFormRow>

              <CFormRow label="Año">
                <c-input type="number" v-model="editedData.year" placeholder="2024" />
              </CFormRow>
            </div>
          </div>

          <!-- Categories -->
          <div class="edit-card">
            <div class="edit-card__header">
              <h2 class="edit-card__title">
                <CIcon icon="tag" :size="16" />
                Categorías
              </h2>
              <button
                v-if="content.tmdb_id && SiteSettings.enable_category_auto_assignment"
                class="edit-card__sync-btn"
                :disabled="syncingCategories"
                @click="syncCategoriesFromTmdb"
              >
                <CIcon icon="refreshCw" :size="13" :class="syncingCategories ? 'animate-spin' : ''" />
                {{ syncingCategories ? 'Sincronizando…' : 'TMDB' }}
              </button>
            </div>

            <div v-if="categoriesLoading" class="edit-card__loading">
              <div class="edit-card__loading-dot" />
              Cargando…
            </div>
            <div v-else-if="categories.length === 0" class="edit-card__empty">
              No hay categorías.
              <a href="/admin/content-manager/categories" class="edit-card__link">Crear categorías</a>
            </div>
            <div v-else class="edit-card__chip-grid">
              <label
                v-for="cat in categories"
                :key="cat.id"
                class="edit-card__chip"
                :class="{ 'edit-card__chip--active': editedData.category_ids?.includes(cat.id) }"
              >
                <input
                  type="checkbox"
                  :value="cat.id"
                  v-model="editedData.category_ids"
                  class="sr-only"
                />
                {{ cat.name }}
              </label>
            </div>
          </div>

          <!-- Content rating + descriptors -->
          <div class="edit-card">
            <div class="edit-card__header">
              <h2 class="edit-card__title">
                <CIcon icon="shieldAlert" :size="16" />
                Clasificación
              </h2>
              <button
                v-if="content.tmdb_id"
                class="edit-card__sync-btn"
                :disabled="syncingRating"
                @click="syncRatingFromTmdb"
              >
                <CIcon icon="refreshCw" :size="13" :class="syncingRating ? 'animate-spin' : ''" />
                {{ syncingRating ? 'Sincronizando…' : 'TMDB' }}
              </button>
            </div>

            <div class="edit-card__fields">
              <CFormRow label="Rating">
                <div class="flex gap-2 items-center">
                  <c-select
                    class="flex-1"
                    :options="ratingOptions"
                    v-model="editedData.content_rating_id"
                    placeholder="Sin clasificación"
                  />
                  <button
                    v-if="editedData.content_rating_id"
                    class="edit-card__clear-btn"
                    @click="editedData.content_rating_id = null"
                    title="Limpiar"
                  >
                    <CIcon icon="x" :size="14" />
                  </button>
                </div>
              </CFormRow>
            </div>

            <div v-if="descriptors.length" class="mt-4">
              <p class="edit-card__sublabel">Descriptores de contenido</p>
              <div class="edit-card__chip-grid mt-2">
                <label
                  v-for="desc in descriptors"
                  :key="desc.key"
                  class="edit-card__chip"
                  :class="{
                    'edit-card__chip--active': editedData.descriptor_keys?.includes(desc.key),
                    'edit-card__chip--low': desc.severity_level === 1,
                    'edit-card__chip--mid': desc.severity_level === 2,
                    'edit-card__chip--high': desc.severity_level === 3,
                  }"
                >
                  <input
                    type="checkbox"
                    :value="desc.key"
                    v-model="editedData.descriptor_keys"
                    class="sr-only"
                  />
                  {{ desc.name }}
                </label>
              </div>
            </div>
          </div>

        </section>

        <!-- ══ TAB: Multimedia ══════════════════════════════════════════════ -->
        <section v-show="activeTab === 'media'" class="edit-page__section-grid">

          <!-- Images -->
          <div class="edit-card edit-card--full">
            <h2 class="edit-card__title">
              <CIcon icon="image" :size="16" />
              Imágenes
            </h2>
            <div class="edit-card__image-grid">
              <div>
                <p class="edit-card__sublabel">Poster <span class="edit-card__ratio-hint">2:3</span></p>
                <c-image-upload
                  v-model="editedData.cover"
                  :modelValue="editedData.cover || content.cover"
                  aspect-ratio="2:3"
                />
              </div>
              <div>
                <p class="edit-card__sublabel">Backdrop <span class="edit-card__ratio-hint">16:9</span></p>
                <c-image-upload
                  v-model="editedData.banner"
                  :modelValue="editedData.banner || content.banner"
                  aspect-ratio="16:9"
                />
              </div>
            </div>
          </div>

          <!-- Logo -->
          <div class="edit-card edit-card--full">
            <div class="edit-card__header">
              <div>
                <h2 class="edit-card__title">
                  <CIcon icon="type" :size="16" />
                  Logo
                </h2>
                <p class="edit-card__subtitle">PNG/WebP transparente. Reemplaza el título en el carrusel.</p>
              </div>
              <div class="flex gap-2">
                <button
                  v-if="content.images?.logo?.original?.webp"
                  class="edit-card__action-btn edit-card__action-btn--danger"
                  @click="deleteLogo"
                >
                  <CIcon icon="trash2" :size="13" />
                  Eliminar
                </button>
                <button
                  v-if="content.tmdb_id"
                  class="edit-card__sync-btn"
                  :disabled="syncingLogo"
                  @click="syncLogoFromTmdb"
                >
                  <CIcon icon="refreshCw" :size="13" :class="syncingLogo ? 'animate-spin' : ''" />
                  {{ syncingLogo ? 'Sincronizando…' : 'TMDB' }}
                </button>
              </div>
            </div>

            <div class="edit-card__image-grid">
              <div>
                <c-image-upload
                  v-model="editedData.logo"
                  :modelValue="editedData.logo || content.images?.logo?.original?.webp"
                  aspect-ratio="3:1"
                />
              </div>
              <div
                v-if="content.images?.logo?.original?.webp"
                class="edit-card__logo-preview"
              >
                <p class="edit-card__sublabel">Preview actual</p>
                <div class="edit-card__logo-box">
                  <img
                    :src="content.images.logo.original.webp"
                    alt="Logo preview"
                    class="max-h-14 object-contain"
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- Trailer -->
          <div class="edit-card edit-card--full">
            <div class="edit-card__header">
              <div>
                <h2 class="edit-card__title">
                  <CIcon icon="play" :size="16" />
                  Trailer
                </h2>
                <p class="edit-card__subtitle">
                  {{ hasTrailer ? trailerSummary : 'Sin trailer configurado' }}
                </p>
              </div>
              <div class="flex gap-2">
                <button
                  v-if="hasTrailer"
                  class="edit-card__action-btn edit-card__action-btn--danger"
                  @click="deleteTrailer"
                >
                  <CIcon icon="trash2" :size="13" />
                  Eliminar
                </button>
                <CButton @click="trailerModalRef?.setIsOpen(true)" icon="pencil" variant="secondary" size="sm">
                  {{ hasTrailer ? 'Editar' : 'Agregar' }}
                </CButton>
              </div>
            </div>
          </div>
          <CTrailerManagerModal
            :content-id="content.id"
            ref="trailerModalRef"
            @updated="fetchContent"
          />

          <!-- Video sources — only for non-TV shows -->
          <div
            v-if="(editedData.content_type || content.content_type) !== 'TVSHOW'"
            class="edit-card edit-card--full"
          >
            <h2 class="edit-card__title">
              <CIcon icon="film" :size="16" />
              Fuentes de video
            </h2>
            <CVideoableManager
              :content-id="content.id"
              :season-id="null"
              :episode-id="null"
              :initial-video-sources="content.video_sources"
              :enable-transcoding="SiteSettings.enable_transcoding"
              @video-source-added="fetchContent"
            />
          </div>

        </section>

        <!-- ══ TAB: Publicación ════════════════════════════════════════════ -->
        <section v-show="activeTab === 'publish'" class="edit-page__section-grid">

          <!-- Status toggles -->
          <div class="edit-card">
            <h2 class="edit-card__title">
              <CIcon icon="toggleRight" :size="16" />
              Estado
            </h2>

            <div class="edit-card__toggle-list">
              <!-- Available -->
              <div class="edit-card__toggle-row">
                <div>
                  <p class="edit-card__toggle-label">Visible para usuarios</p>
                  <p class="edit-card__toggle-hint">Aparece en la plataforma</p>
                </div>
                <button
                  class="edit-toggle"
                  :class="editedData.available ? 'edit-toggle--on' : ''"
                  @click="editedData.available = !editedData.available"
                  :aria-pressed="editedData.available"
                >
                  <span class="edit-toggle__thumb" />
                </button>
              </div>

              <!-- Premium -->
              <div class="edit-card__toggle-row edit-card__toggle-row--premium">
                <div>
                  <p class="edit-card__toggle-label">
                    <CIcon icon="sparkles" :size="13" />
                    Premium
                  </p>
                  <p class="edit-card__toggle-hint">Solo suscriptores</p>
                </div>
                <button
                  class="edit-toggle edit-toggle--premium"
                  :class="editedData.premium ? 'edit-toggle--on' : ''"
                  @click="editedData.premium = !editedData.premium"
                  :aria-pressed="editedData.premium"
                >
                  <span class="edit-toggle__thumb" />
                </button>
              </div>
            </div>
          </div>

          <!-- Scheduled launch -->
          <div class="edit-card">
            <div class="edit-card__header">
              <div>
                <h2 class="edit-card__title">
                  <CIcon icon="calendarClock" :size="16" />
                  Estreno programado
                </h2>
                <p class="edit-card__subtitle">Publicar automáticamente en una fecha</p>
              </div>
              <button
                class="edit-toggle"
                :class="isScheduled ? 'edit-toggle--on' : ''"
                @click="toggleSchedule"
                :aria-pressed="isScheduled"
              >
                <span class="edit-toggle__thumb" />
              </button>
            </div>

            <transition name="fade">
              <div v-if="isScheduled" class="edit-card__fields mt-4">
                <CFormRow label="Fecha">
                  <CInput type="date" v-model="scheduleDate" :min="todayStr" />
                </CFormRow>
                <CFormRow label="Hora">
                  <c-select
                    v-model="scheduleHour"
                    :options="hours.map(h => ({ label: h + ':00', value: h }))"
                  />
                </CFormRow>
                <p v-if="formattedScheduleDate" class="edit-card__schedule-hint">
                  <CIcon icon="clock" :size="13" />
                  Se publicará el {{ formattedScheduleDate }}
                </p>
              </div>
            </transition>
          </div>

          <!-- Merchandising badge -->
          <div class="edit-card">
            <h2 class="edit-card__title">
              <CIcon icon="tag" :size="16" />
              Badge merchandising
            </h2>
            <p class="edit-card__subtitle">
              Badge inline en el hero y detalle del contenido.
            </p>

            <div class="edit-card__fields mt-4">
              <CFormRow label="Tipo">
                <c-select :options="badgeTypeOptions" v-model="badge.badge_type" />
              </CFormRow>
              <CFormRow label="Texto">
                <c-input v-model="badge.label" placeholder="Ej: Nuevo episodio" />
              </CFormRow>
              <CFormRow label="Icono">
                <CIconPicker v-model="badge.icon" placeholder="Seleccionar icono…" />
              </CFormRow>
              <CFormRow label="Color">
                <div class="flex items-center gap-2">
                  <input
                    type="color"
                    v-model="badge.color"
                    class="edit-card__color-swatch"
                  />
                  <c-input v-model="badge.color" placeholder="#ffffff" class="flex-1" />
                </div>
              </CFormRow>
              <CFormRow v-if="showBadgeExpiry" label="Expira el">
                <c-input type="datetime-local" v-model="badge.expires_at" />
              </CFormRow>
            </div>

            <!-- Preview -->
            <div v-if="badge.label" class="edit-card__badge-preview">
              <p class="edit-card__sublabel mb-2">Preview</p>
              <span
                class="inline-flex items-center gap-1.5 text-sm font-medium"
                :style="{ color: badge.color || 'rgba(255,255,255,0.85)' }"
              >
                <CIcon v-if="badge.icon" :icon="badge.icon" :size="14" />
                {{ badge.label }}
              </span>
            </div>

            <div class="flex gap-2 mt-4">
              <CButton
                variant="primary"
                icon="check"
                :loading="loadingButton"
                class="flex-1 justify-center"
                @click="saveBadge"
              >
                {{ hasBadge ? 'Actualizar' : 'Crear' }} badge
              </CButton>
              <CButton
                v-if="hasBadge"
                variant="danger"
                icon="trash2"
                @click="deleteBadge"
              />
            </div>
          </div>

        </section>

        <!-- ══ TAB: Temporadas ════════════════════════════════════════════ -->
        <section
          v-show="activeTab === 'seasons'"
          v-if="(editedData.content_type || content.content_type) === 'TVSHOW'"
          class="edit-page__section-grid"
        >
          <div class="edit-card edit-card--full">
            <div class="edit-card__header">
              <h2 class="edit-card__title">
                <CIcon icon="layers" :size="16" />
                Temporadas
              </h2>
              <CButton icon="plus" @click="addSeason">Agregar</CButton>
            </div>

            <div v-if="!content.seasons?.length" class="edit-card__empty-lg">
              <CIcon icon="layers" :size="36" class="mb-3 opacity-20" />
              <p>No hay temporadas todavía.</p>
            </div>

            <draggable
              v-else
              tag="div"
              v-model="content.seasons"
              class="edit-card__season-list"
              :group="seasonGroup"
              handle=".handle"
              ghost-class="opacity-40"
              @start="reorderingSeasons = true"
              @end="reorderingSeasons = false"
            >
              <template #item="{ element }">
                <div class="edit-season-row">
                  <CIcon icon="gripVertical" :size="16" class="handle edit-season-row__grip" />

                  <div class="edit-season-row__info">
                    <p class="edit-season-row__title">{{ element.title }}</p>
                    <p class="edit-season-row__meta">
                      {{ element.episodes_count || 0 }} episodios
                    </p>
                  </div>

                  <div class="edit-season-row__actions">
                    <button class="edit-season-row__btn" @click="editSeason(element)" title="Editar temporada">
                      <CIcon icon="pencil" :size="14" />
                    </button>
                    <button class="edit-season-row__btn" @click="editSeasonEpisodes(element.id)" title="Ver episodios">
                      <CIcon icon="list" :size="14" />
                      <span>Episodios</span>
                    </button>
                    <button class="edit-season-row__btn edit-season-row__btn--danger" @click="deleteSeason(element)" title="Eliminar">
                      <CIcon icon="trash2" :size="14" />
                    </button>
                  </div>
                </div>
              </template>
            </draggable>
          </div>

          <add-season-modal
            :content="content"
            ref="addSeasonModalRef"
            @season-created="fetchContent"
          />
          <edit-season-modal
            :content-id="contentId"
            ref="editSeasonModalRef"
            @season-updated="fetchContent"
          />
        </section>

        <!-- ══ TAB: Cast ══════════════════════════════════════════════════ -->
        <section v-show="activeTab === 'cast'" class="edit-page__section-grid">
          <div class="edit-card edit-card--full">
            <div class="edit-card__header">
              <h2 class="edit-card__title">
                <CIcon icon="users" :size="16" />
                Cast
              </h2>
              <button
                v-if="content.tmdb_id && SiteSettings.enable_metadata_recommendation"
                class="edit-card__sync-btn"
                :disabled="syncingCast"
                @click="syncCastFromTmdb"
              >
                <CIcon icon="refreshCw" :size="13" :class="syncingCast ? 'animate-spin' : ''" />
                {{ syncingCast ? 'Importando…' : 'Sincronizar TMDB' }}
              </button>
            </div>

            <div v-if="!content.cast_members?.length" class="edit-card__empty-lg">
              <CIcon icon="users" :size="36" class="mb-3 opacity-20" />
              <p v-if="content.tmdb_id">
                No hay cast importado.
                <span v-if="SiteSettings.enable_metadata_recommendation">
                  Haz clic en "Sincronizar TMDB".
                </span>
              </p>
              <p v-else class="text-sm">Sin TMDB ID — asigna uno para poder importar el cast.</p>
            </div>

            <div v-else class="edit-card__cast-grid">
              <div
                v-for="cm in content.cast_members"
                :key="cm.id"
                class="cast-card"
              >
                <div class="cast-card__photo">
                  <img
                    v-if="cm.person?.profile_path"
                    :src="`https://image.tmdb.org/t/p/w185${cm.person.profile_path}`"
                    :alt="cm.person?.name"
                    loading="lazy"
                  />
                  <CIcon v-else icon="user" :size="24" class="opacity-30" />
                </div>
                <p class="cast-card__name">{{ cm.person?.name }}</p>
                <p class="cast-card__character">{{ cm.character_name }}</p>
                <button class="cast-card__remove" @click="removeCastMember(cm.id)">
                  <CIcon icon="x" :size="12" />
                </button>
              </div>
            </div>
          </div>
        </section>

      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, inject, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { Trash2Icon, PlusIcon, EditIcon } from 'lucide-vue-next';
import { toast } from 'vue3-toastify';
import { format, parseISO, formatDistanceToNow } from 'date-fns';
import { es } from 'date-fns/locale';
import draggable from 'vuedraggable';

import { ajax } from '@/lib/Ajax';
import CIcon from '@/components/c-icon.vue';
import CButton from '@/components/forms/c-button';
import CFormRow from '@/components/forms/CFormRow';
import CInput from '@/components/forms/c-input.vue';
import CSelect from '@/components/forms/c-select.vue';
import CIconPicker from '@/components/forms/CIconPicker';
import CVideoableManager from '@/components/CVideoableManager';
import CTrailerManagerModal from '@/components/modals/trailer-manager.modal';
import addSeasonModal from '@/components/modals/add-season.modal.vue';
import editSeasonModal from '@/components/modals/edit-season.modal.vue';

// ── Injections ─────────────────────────────────────────────────────────────
const SiteSettings = inject('SiteSettings');
const route = useRoute();
const router = useRouter();
const contentId = route.params.id;

// ── Tab navigation ──────────────────────────────────────────────────────────
const activeTab = ref('general');

const tabs = computed(() => {
  const base = [
    { key: 'general',  label: 'General',     icon: 'fileText'   },
    { key: 'media',    label: 'Multimedia',   icon: 'image'      },
    { key: 'publish',  label: 'Publicación',  icon: 'send'       },
    { key: 'cast',     label: 'Cast',         icon: 'users'      },
  ];
  if ((editedData.value.content_type || content.value.content_type) === 'TVSHOW') {
    base.splice(3, 0, { key: 'seasons', label: 'Temporadas', icon: 'layers' });
  }
  return base;
});

// ── State ───────────────────────────────────────────────────────────────────
const loading       = ref(true);
const loadingButton = ref(false);
const content       = ref({});
const editedData    = ref({});

// Refs for child components
const addSeasonModalRef  = ref();
const editSeasonModalRef = ref();
const trailerModalRef    = ref();
const reorderingSeasons  = ref(false);

// Categories
const categories        = ref([]);
const categoriesLoading = ref(false);
const syncingCategories = ref(false);

// Ratings & descriptors
const contentRatings    = ref([]);
const ratingsLoading    = ref(false);
const descriptors       = ref([]);
const descriptorsLoading = ref(false);
const syncingRating     = ref(false);

// Cast / logo / trailer sync
const syncingCast  = ref(false);
const syncingLogo  = ref(false);

// Schedule
const scheduleDate = ref('');
const scheduleHour = ref('20');
const hours        = Array.from({ length: 24 }, (_, i) => String(i).padStart(2, '0'));
const todayStr     = new Date().toISOString().split('T')[0];

// Badge
const badge = ref({ badge_type: 'programming', label: '', icon: '', color: '', expires_at: null });
const badgeTypeOptions = [
  { value: 'programming',  label: 'Programación / Estado'    },
  { value: 'prestige',     label: 'Prestigio / Premios'      },
  { value: 'availability', label: 'Disponibilidad / Urgencia' },
];

// ── Computed ────────────────────────────────────────────────────────────────
const contentTypes = [
  { value: 'MOVIE',  label: 'Película' },
  { value: 'TVSHOW', label: 'Serie'    },
];

const contentTypeLabel = computed(() => {
  const t = editedData.value.content_type || content.value.content_type;
  return t === 'TVSHOW' ? 'Serie' : 'Película';
});

const hasTrailer = computed(() =>
  content.value.trailer_url || content.value.trailer_video_sources?.length > 0
);

const trailerSummary = computed(() => {
  if (content.value.trailer_video_sources?.length) {
    const vs = content.value.trailer_video_sources[0];
    return `${vs.format?.toUpperCase() || 'Video'} · ${vs.quality || ''}`;
  }
  return content.value.trailer_url ? 'URL externa' : '';
});

const isScheduled = computed(() =>
  !!editedData.value.scheduled_launch_at || !!scheduleDate.value
);

const formattedScheduleDate = computed(() => {
  if (!scheduleDate.value) return '';
  const d = new Date(`${scheduleDate.value}T${scheduleHour.value}:00:00`);
  return format(d, "EEEE d 'de' MMMM", { locale: es }) + ` a las ${scheduleHour.value}:00`;
});

const scheduledCountdown = computed(() => {
  if (!content.value.scheduled_launch_at) return '';
  const dt = parseISO(content.value.scheduled_launch_at);
  if (dt <= new Date()) return '';
  return formatDistanceToNow(dt, { addSuffix: true, locale: es });
});

const ratingOptions = computed(() =>
  contentRatings.value.map(r => ({ value: r.code, label: `${r.name} — ${r.description || ''}` }))
);

const hasBadge     = computed(() => content.value.content_badges?.length > 0);
const existingBadge = computed(() => content.value.content_badges?.[0] || null);
const showBadgeExpiry = computed(() => badge.value.badge_type === 'availability');

const seasonGroup = { name: 'seasons', put: true, pull: true };

// ── Watchers ────────────────────────────────────────────────────────────────
watch(scheduleDate, syncScheduleToEditedData);
watch(scheduleHour, syncScheduleToEditedData);

watch(reorderingSeasons, async (val) => {
  if (val === false) await saveSeasonsOrder();
});

// ── Helpers ──────────────────────────────────────────────────────────────────
function syncScheduleToEditedData() {
  if (scheduleDate.value) {
    editedData.value.scheduled_launch_at =
      new Date(`${scheduleDate.value}T${scheduleHour.value}:00:00`).toISOString();
  }
}

// ── Data fetchers ────────────────────────────────────────────────────────────
const fetchContent = async () => {
  try {
    const { data } = await ajax.get(`/admin/content-manager/${contentId}.json`);
    content.value = data.data;
    editedData.value = Object.fromEntries(
      Object.entries(content.value).filter(([k]) => !['banner', 'cover'].includes(k))
    );
    editedData.value.category_ids    = content.value.categories?.map(c => c.id) || [];
    editedData.value.content_rating_id = content.value.content_rating?.code || content.value.content_rating_id || null;
    editedData.value.descriptor_keys = content.value.content_descriptors?.map(d => d.key) || [];

    if (content.value.scheduled_launch_at) {
      const dt = parseISO(content.value.scheduled_launch_at);
      scheduleDate.value = format(dt, 'yyyy-MM-dd');
      scheduleHour.value = format(dt, 'HH');
    }

    initBadgeFromContent();
  } catch {
    toast.error('Error al cargar el contenido');
  } finally {
    loading.value = false;
  }
};

const fetchCategories = async () => {
  categoriesLoading.value = true;
  try {
    const { data } = await ajax.get('/admin/categories.json');
    categories.value = data.data || [];
  } finally {
    categoriesLoading.value = false;
  }
};

const fetchContentRatings = async () => {
  ratingsLoading.value = true;
  try {
    const { data } = await ajax.get('/admin/content-ratings.json');
    contentRatings.value = data.data || [];
  } finally {
    ratingsLoading.value = false;
  }
};

const fetchContentDescriptors = async () => {
  descriptorsLoading.value = true;
  try {
    const { data } = await ajax.get('/admin/content-descriptors.json');
    descriptors.value = data.data || [];
  } finally {
    descriptorsLoading.value = false;
  }
};

// ── Badge ────────────────────────────────────────────────────────────────────
const initBadgeFromContent = () => {
  const b = existingBadge.value;
  badge.value = b
    ? {
        badge_type: b.badge_type || 'programming',
        label:      b.label      || '',
        icon:       b.icon       || '',
        color:      b.color      || '',
        expires_at: b.expires_at ? format(parseISO(b.expires_at), "yyyy-MM-dd'T'HH:mm") : null,
      }
    : { badge_type: 'programming', label: '', icon: '', color: '', expires_at: null };
};

const saveBadge = async () => {
  if (!badge.value.label.trim()) { toast.error('El label del badge es obligatorio'); return; }
  loadingButton.value = true;
  try {
    const f = new FormData();
    if (existingBadge.value?.id) f.append('content[content_badges_attributes][][id]', existingBadge.value.id);
    f.append('content[content_badges_attributes][][badge_type]', badge.value.badge_type);
    f.append('content[content_badges_attributes][][label]',      badge.value.label.trim());
    f.append('content[content_badges_attributes][][icon]',       badge.value.icon  || '');
    f.append('content[content_badges_attributes][][color]',      badge.value.color || '');
    f.append('content[content_badges_attributes][][expires_at]', badge.value.expires_at || '');
    f.append('content[content_badges_attributes][][position]',   '0');
    f.append('content[content_badges_attributes][][active]',     'true');
    await ajax.put(`/admin/content-manager/${contentId}.json`, f);
    toast.success('Badge guardado');
    await fetchContent();
  } catch { toast.error('Error al guardar el badge'); }
  finally { loadingButton.value = false; }
};

const deleteBadge = async () => {
  if (!existingBadge.value || !confirm('¿Eliminar el badge?')) return;
  loadingButton.value = true;
  try {
    const f = new FormData();
    f.append('content[content_badges_attributes][][id]',       existingBadge.value.id);
    f.append('content[content_badges_attributes][][_destroy]', '1');
    await ajax.put(`/admin/content-manager/${contentId}.json`, f);
    toast.success('Badge eliminado');
    await fetchContent();
  } catch { toast.error('Error al eliminar el badge'); }
  finally { loadingButton.value = false; }
};

// ── Sync helpers ─────────────────────────────────────────────────────────────
const syncCategoriesFromTmdb = async () => {
  if (!confirm('Sincronizar categorías de TMDB?')) return;
  syncingCategories.value = true;
  try {
    const { data } = await ajax.post(`/admin/content-manager/${contentId}/sync-categories.json`);
    toast.success(`${data.assigned_count} categorías asignadas`);
    await fetchContent();
  } catch { toast.error('Error al sincronizar categorías'); }
  finally { syncingCategories.value = false; }
};

const syncRatingFromTmdb = async () => {
  if (!confirm('Obtener clasificación de TMDB?')) return;
  syncingRating.value = true;
  try {
    const { data } = await ajax.post(`/admin/content-manager/${contentId}/sync-rating.json`);
    toast.success(data.message || 'Clasificación sincronizada');
    await fetchContent();
  } catch (e) { toast.error(e.response?.data?.error || 'Error al sincronizar'); }
  finally { syncingRating.value = false; }
};

const syncLogoFromTmdb = async () => {
  syncingLogo.value = true;
  try {
    const { data } = await ajax.post(`/admin/content-manager/${contentId}/sync-logo.json`);
    toast.success(data.message || 'Logo sincronizado');
    await fetchContent();
  } catch (e) { toast.error(e.response?.data?.error || 'Error al sincronizar logo'); }
  finally { syncingLogo.value = false; }
};

const deleteLogo = async () => {
  if (!confirm('Eliminar logo?')) return;
  const f = new FormData();
  f.append('content[logo]', '');
  await ajax.put(`/admin/content-manager/${contentId}.json`, f);
  toast.success('Logo eliminado');
  await fetchContent();
};

const deleteTrailer = async () => {
  if (!confirm('¿Eliminar el trailer?')) return;
  try {
    if (content.value.trailer_video_sources?.length) {
      for (const vs of content.value.trailer_video_sources)
        await ajax.delete(`/admin/video_sources/${vs.id}.json`);
    }
    if (content.value.trailer_url) {
      const f = new FormData();
      f.append('content[trailer_url]', '');
      await ajax.put(`/admin/content-manager/${contentId}.json`, f);
    }
    toast.success('Trailer eliminado');
    await fetchContent();
  } catch { toast.error('Error al eliminar el trailer'); }
};

const syncCastFromTmdb = async () => {
  if (!confirm('Sincronizar cast de TMDB?')) return;
  syncingCast.value = true;
  try {
    const { data } = await ajax.post(`/admin/content-manager/${contentId}/sync-cast.json`);
    toast.success(`${data.assigned_count} miembros importados`);
    await fetchContent();
  } catch { toast.error('Error al sincronizar cast'); }
  finally { syncingCast.value = false; }
};

const removeCastMember = async (id) => {
  if (!confirm('¿Quitar este miembro del cast?')) return;
  await ajax.delete(`/admin/content-manager/${contentId}/cast-members/${id}.json`);
  toast.success('Miembro eliminado');
  await fetchContent();
};

// ── Schedule ─────────────────────────────────────────────────────────────────
const toggleSchedule = () => {
  if (isScheduled.value) {
    editedData.value.scheduled_launch_at = null;
    scheduleDate.value = '';
    scheduleHour.value = '20';
  } else {
    scheduleDate.value = todayStr;
    scheduleHour.value = '20';
    syncScheduleToEditedData();
  }
};

// ── Seasons ───────────────────────────────────────────────────────────────────
const addSeason        = () => addSeasonModalRef.value?.setIsOpen(true);
const editSeason       = (s) => editSeasonModalRef.value?.setIsOpen(true, s);
const editSeasonEpisodes = (id) => router.push(`/admin/content-manager/${contentId}/seasons/${id}/episodes`);

const deleteSeason = async (season) => {
  if (!confirm(`¿Eliminar "${season.title}"?`)) return;
  await ajax.delete(`/admin/content-manager/${contentId}/seasons/${season.id}.json`);
  toast.success('Temporada eliminada');
  await fetchContent();
};

const saveSeasonsOrder = async () => {
  await ajax.put(`/admin/content-manager/${contentId}/reorder-seasons.json`, {
    season_order: content.value.seasons.map(s => s.id),
  });
};

// ── Save / Delete content ─────────────────────────────────────────────────────
const saveContent = async (e) => {
  if (e?.preventDefault) e.preventDefault();
  loadingButton.value = true;
  try {
    const f = new FormData();
    const skip = ['id', 'created_at', 'updated_at', 'seasons'];
    const nullable = ['scheduled_launch_at'];

    for (const [key, value] of Object.entries(editedData.value)) {
      if (skip.includes(key) || value === undefined) continue;
      if (value === null && !nullable.includes(key)) continue;

      if (key === 'category_ids' && Array.isArray(value)) {
        value.forEach(id => f.append('content[category_ids][]', id));
      } else if (key === 'descriptor_keys' && Array.isArray(value)) {
        value.forEach(k  => f.append('content[content_descriptor_keys][]', k));
      } else if (key === 'content_rating_id') {
        f.append('content[content_rating_id]', value || '');
      } else {
        f.append(`content[${key}]`, value);
      }
    }

    if ([...f.entries()].length === 0) {
      toast.info('No se ha modificado ningún dato.');
      return;
    }

    await ajax.put(`/admin/content-manager/${contentId}.json`, f);
    toast.success('Contenido guardado.');
    await fetchContent();
  } catch (e) {
    toast.error('Error al guardar: ' + (e?.response?.data?.error || e.message));
  } finally {
    loadingButton.value = false;
  }
};

const deleteContent = async () => {
  if (!confirm('¿Eliminar este contenido? Esta acción no se puede deshacer.')) return;
  await ajax.delete(`/admin/content-manager/${contentId}.json`);
  toast.success('Contenido eliminado');
  router.push({ name: 'admin.content.manager.all' });
};

// ── Mount ─────────────────────────────────────────────────────────────────────
onMounted(() => {
  fetchContent();
  fetchCategories();
  fetchContentRatings();
  fetchContentDescriptors();
});
</script>

<style scoped>
/* ── Loader ──────────────────────────────────────────────────────────────── */
.edit-page__loader {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 50vh;
  gap: var(--space-3);
}
.edit-page__loader-spinner {
  width: 40px;
  height: 40px;
  border: 2px solid rgba(255,255,255,.15);
  border-top-color: var(--c-primary-color, #00A8E1);
  border-radius: 50%;
  animation: spin .8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
.edit-page__loader-text { font-size: .875rem; color: rgba(255,255,255,.45); }

/* ── Page shell ──────────────────────────────────────────────────────────── */
.edit-page { display: flex; flex-direction: column; min-height: 100vh; }

/* ── Hero ────────────────────────────────────────────────────────────────── */
.edit-page__hero {
  position: relative;
  padding: var(--space-6) var(--space-6) var(--space-7);
  overflow: hidden;
  background: var(--c-background-secondary, #111);
}
.edit-page__hero-backdrop {
  position: absolute;
  inset: 0;
  background-image: var(--hero-backdrop);
  background-size: cover;
  background-position: center top;
  opacity: .12;
  filter: blur(24px);
  pointer-events: none;
}
.edit-page__hero-inner {
  position: relative;
  display: flex;
  align-items: flex-end;
  gap: var(--space-4);
  max-width: 1280px;
  margin: 0 auto;
}
.edit-page__back-btn {
  flex-shrink: 0;
  align-self: flex-start;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: var(--radius-full, 9999px);
  background: rgba(255,255,255,.08);
  border: none;
  color: rgba(255,255,255,.7);
  cursor: pointer;
  transition: background .15s;
}
.edit-page__back-btn:hover { background: rgba(255,255,255,.14); }

.edit-page__hero-meta { flex: 1; min-width: 0; }

.edit-page__hero-badges {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-bottom: var(--space-2);
}
.edit-page__type-chip {
  font-size: .65rem;
  font-weight: 700;
  letter-spacing: .08em;
  text-transform: uppercase;
  padding: 2px 8px;
  border-radius: var(--radius-full, 9999px);
  background: rgba(255,255,255,.12);
  color: rgba(255,255,255,.7);
}
.edit-page__status-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: .65rem;
  font-weight: 600;
  letter-spacing: .06em;
  text-transform: uppercase;
  padding: 2px 8px;
  border-radius: var(--radius-full, 9999px);
}
.edit-page__status-chip--available { background: rgba(34,197,94,.15); color: #4ade80; }
.edit-page__status-chip--hidden    { background: rgba(255,255,255,.08); color: rgba(255,255,255,.4); }
.edit-page__status-chip--premium   { background: rgba(234,179,8,.15);  color: #fbbf24; }

.edit-page__hero-title {
  font-size: clamp(1.4rem, 3vw, 2rem);
  font-weight: 700;
  color: #fff;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin: 0;
  line-height: 1.2;
}
.edit-page__scheduled-hint {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  margin-top: var(--space-2);
  font-size: .8rem;
  color: rgba(99,179,237,.9);
}
.edit-page__hero-actions {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: var(--space-2);
  align-self: flex-end;
}

/* ── Body (nav + main) ───────────────────────────────────────────────────── */
.edit-page__body {
  display: flex;
  flex: 1;
  max-width: 1280px;
  width: 100%;
  margin: 0 auto;
  padding: var(--space-6) var(--space-4);
  gap: var(--space-6);
}

/* ── Left nav ────────────────────────────────────────────────────────────── */
.edit-page__nav {
  display: flex;
  flex-direction: column;
  gap: 2px;
  width: 180px;
  flex-shrink: 0;
}
.edit-page__nav-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: 10px 14px;
  border-radius: var(--radius-md, 8px);
  border: none;
  background: transparent;
  color: rgba(255,255,255,.5);
  font-size: .875rem;
  font-weight: 500;
  cursor: pointer;
  transition: background .15s, color .15s;
  text-align: left;
}
.edit-page__nav-item:hover { background: rgba(255,255,255,.06); color: rgba(255,255,255,.8); }
.edit-page__nav-item--active {
  background: rgba(255,255,255,.1);
  color: #fff;
}

/* ── Main content ────────────────────────────────────────────────────────── */
.edit-page__main { flex: 1; min-width: 0; }

.edit-page__section-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-4);
}
@media (max-width: 900px) {
  .edit-page__body { flex-direction: column; }
  .edit-page__nav { width: 100%; flex-direction: row; flex-wrap: wrap; }
  .edit-page__section-grid { grid-template-columns: 1fr; }
}

/* ── Card ────────────────────────────────────────────────────────────────── */
.edit-card {
  background: rgba(255,255,255,.04);
  border: 1px solid rgba(255,255,255,.07);
  border-radius: var(--radius-lg, 12px);
  padding: var(--space-5);
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}
.edit-card--full { grid-column: 1 / -1; }
.edit-card__title {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: .9rem;
  font-weight: 600;
  color: #fff;
  margin: 0;
}
.edit-card__subtitle { font-size: .8rem; color: rgba(255,255,255,.4); margin: 0; }
.edit-card__sublabel {
  font-size: .75rem;
  font-weight: 500;
  color: rgba(255,255,255,.45);
  text-transform: uppercase;
  letter-spacing: .05em;
}
.edit-card__ratio-hint {
  font-size: .7rem;
  font-weight: 400;
  color: rgba(255,255,255,.3);
}
.edit-card__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-3);
}
.edit-card__fields { display: flex; flex-direction: column; gap: var(--space-3); }
.edit-card__image-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-4);
}
.edit-card__logo-box {
  background: rgba(0,0,0,.3);
  border-radius: var(--radius-md);
  padding: var(--space-4);
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 80px;
}

/* Sync button */
.edit-card__sync-btn {
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 4px 10px;
  font-size: .72rem;
  font-weight: 600;
  letter-spacing: .04em;
  border-radius: var(--radius-full, 9999px);
  border: none;
  background: rgba(var(--c-primary-rgb, 0,168,225), .15);
  color: var(--c-primary-color, #00A8E1);
  cursor: pointer;
  transition: background .15s;
  white-space: nowrap;
}
.edit-card__sync-btn:hover { background: rgba(var(--c-primary-rgb, 0,168,225), .25); }
.edit-card__sync-btn:disabled { opacity: .5; cursor: not-allowed; }

.edit-card__action-btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 4px 10px;
  font-size: .72rem;
  font-weight: 600;
  border-radius: var(--radius-full, 9999px);
  border: none;
  cursor: pointer;
  transition: background .15s;
}
.edit-card__action-btn--danger {
  background: rgba(239,68,68,.12);
  color: #f87171;
}
.edit-card__action-btn--danger:hover { background: rgba(239,68,68,.2); }

.edit-card__clear-btn {
  width: 30px;
  height: 30px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--radius-md);
  border: none;
  background: rgba(255,255,255,.06);
  color: rgba(255,255,255,.5);
  cursor: pointer;
}

/* Loading / empty */
.edit-card__loading {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: .8rem;
  color: rgba(255,255,255,.4);
}
.edit-card__loading-dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  background: var(--c-primary-color, #00A8E1);
  animation: pulse 1s infinite;
}
@keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: .3; } }

.edit-card__empty { font-size: .82rem; color: rgba(255,255,255,.35); }
.edit-card__link { color: var(--c-primary-color, #00A8E1); }
.edit-card__empty-lg {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-8) var(--space-4);
  color: rgba(255,255,255,.35);
  font-size: .875rem;
  text-align: center;
}

/* Chip grid (categories / descriptors) */
.edit-card__chip-grid { display: flex; flex-wrap: wrap; gap: var(--space-2); }
.edit-card__chip {
  display: inline-flex;
  align-items: center;
  padding: 5px 12px;
  border-radius: var(--radius-full, 9999px);
  font-size: .78rem;
  font-weight: 500;
  border: 1px solid rgba(255,255,255,.1);
  color: rgba(255,255,255,.55);
  cursor: pointer;
  transition: all .15s;
  background: transparent;
  user-select: none;
}
.edit-card__chip:hover { border-color: rgba(255,255,255,.2); color: rgba(255,255,255,.8); }
.edit-card__chip--active {
  background: rgba(var(--c-primary-rgb, 0,168,225), .18);
  border-color: rgba(var(--c-primary-rgb, 0,168,225), .4);
  color: var(--c-primary-color, #00A8E1);
}
.edit-card__chip--low    { --chip-active: rgba(34,197,94,.18);  --chip-text: #4ade80; }
.edit-card__chip--mid    { --chip-active: rgba(234,179,8,.18);  --chip-text: #fbbf24; }
.edit-card__chip--high   { --chip-active: rgba(239,68,68,.18);  --chip-text: #f87171; }
.edit-card__chip--low.edit-card__chip--active,
.edit-card__chip--mid.edit-card__chip--active,
.edit-card__chip--high.edit-card__chip--active {
  background: var(--chip-active);
  color: var(--chip-text);
  border-color: var(--chip-text);
}

/* Badge preview */
.edit-card__badge-preview {
  padding: var(--space-3);
  border-radius: var(--radius-md);
  background: rgba(255,255,255,.04);
  border: 1px solid rgba(255,255,255,.07);
}

/* Color swatch */
.edit-card__color-swatch {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-md);
  border: 1px solid rgba(255,255,255,.15);
  background: transparent;
  cursor: pointer;
  padding: 2px;
}

/* Schedule hint */
.edit-card__schedule-hint {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: .8rem;
  color: rgba(99,179,237,.85);
}

/* ── Toggle ──────────────────────────────────────────────────────────────── */
.edit-toggle {
  position: relative;
  display: inline-flex;
  align-items: center;
  width: 40px;
  height: 22px;
  border-radius: var(--radius-full, 9999px);
  background: rgba(255,255,255,.15);
  border: none;
  cursor: pointer;
  flex-shrink: 0;
  transition: background .2s;
}
.edit-toggle--on { background: var(--c-primary-color, #00A8E1); }
.edit-toggle--premium.edit-toggle--on { background: #eab308; }
.edit-toggle__thumb {
  position: absolute;
  left: 3px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: #fff;
  transition: transform .2s;
}
.edit-toggle--on .edit-toggle__thumb { transform: translateX(18px); }

.edit-card__toggle-list { display: flex; flex-direction: column; gap: var(--space-3); }
.edit-card__toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  padding: var(--space-3);
  border-radius: var(--radius-md);
  background: rgba(255,255,255,.03);
  border: 1px solid rgba(255,255,255,.06);
}
.edit-card__toggle-row--premium {
  background: rgba(234,179,8,.05);
  border-color: rgba(234,179,8,.12);
}
.edit-card__toggle-label {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: .85rem;
  font-weight: 600;
  color: rgba(255,255,255,.85);
  margin: 0;
}
.edit-card__toggle-hint { font-size: .75rem; color: rgba(255,255,255,.35); margin: 2px 0 0; }

/* ── Seasons list ────────────────────────────────────────────────────────── */
.edit-card__season-list { display: flex; flex-direction: column; gap: var(--space-2); margin-top: var(--space-2); }
.edit-season-row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  border-radius: var(--radius-md);
  background: rgba(255,255,255,.04);
  border: 1px solid rgba(255,255,255,.07);
  transition: border-color .15s;
}
.edit-season-row:hover { border-color: rgba(255,255,255,.14); }
.edit-season-row__grip { color: rgba(255,255,255,.25); cursor: grab; }
.edit-season-row__info { flex: 1; min-width: 0; }
.edit-season-row__title { font-size: .875rem; font-weight: 600; color: #fff; margin: 0; }
.edit-season-row__meta  { font-size: .75rem; color: rgba(255,255,255,.4); margin: 2px 0 0; }
.edit-season-row__actions { display: flex; align-items: center; gap: var(--space-1); }
.edit-season-row__btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 6px 10px;
  border-radius: var(--radius-md);
  border: none;
  background: rgba(255,255,255,.05);
  color: rgba(255,255,255,.55);
  font-size: .75rem;
  font-weight: 500;
  cursor: pointer;
  transition: all .15s;
}
.edit-season-row__btn:hover { background: rgba(255,255,255,.1); color: #fff; }
.edit-season-row__btn--danger:hover { background: rgba(239,68,68,.12); color: #f87171; }

/* ── Cast grid ───────────────────────────────────────────────────────────── */
.edit-card__cast-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  gap: var(--space-3);
  margin-top: var(--space-2);
}
.cast-card {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-1);
}
.cast-card__photo {
  width: 100%;
  aspect-ratio: 2/3;
  border-radius: var(--radius-md);
  overflow: hidden;
  background: rgba(255,255,255,.06);
  display: flex;
  align-items: center;
  justify-content: center;
}
.cast-card__photo img { width: 100%; height: 100%; object-fit: cover; }
.cast-card__name      { font-size: .72rem; font-weight: 600; color: #fff; text-align: center; width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.cast-card__character { font-size: .65rem; color: rgba(255,255,255,.4); text-align: center; width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.cast-card__remove {
  position: absolute;
  top: 4px;
  right: 4px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: rgba(0,0,0,.6);
  border: none;
  color: rgba(255,255,255,.6);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  opacity: 0;
  transition: opacity .15s;
}
.cast-card:hover .cast-card__remove { opacity: 1; }
.cast-card__remove:hover { background: rgba(239,68,68,.8); color: #fff; }

/* ── Transitions ─────────────────────────────────────────────────────────── */
.fade-enter-active, .fade-leave-active { transition: opacity .2s, transform .2s; }
.fade-enter-from, .fade-leave-to { opacity: 0; transform: translateY(-6px); }
</style>
