<template>
  <div class="preferences-page">
    <div class="preferences-page__header">
      <div class="preferences-page__header-content">
        <h1 class="preferences-page__title">
          <CIcon icon="settings" :size="28" class="preferences-page__icon" />
          {{ $t('js.preferences.title') }}
        </h1>
        <p class="preferences-page__description">
          {{ $t('js.preferences.description') }}
        </p>
      </div>
    </div>

    <div v-if="isLoading" class="preferences-page__loading">
      <CIcon icon="loader" :size="24" class="animate-spin" />
      <p>{{ $t('js.preferences.loading') }}</p>
    </div>

    <div v-else class="preferences-page__content">
      <div class="preferences-page__sidebar">
        <nav class="preferences-page__nav">
          <button
            v-for="cat in categories"
            :key="cat"
            class="preferences-page__nav-item"
            :class="{ 'preferences-page__nav-item--active': activeCategory === cat }"
            @click="activeCategory = cat"
          >
            <CIcon :icon="getCategoryIcon(cat)" :size="16" />
            <span>{{ $t(`js.preferences.categories.${cat}`) || cat }}</span>
          </button>
        </nav>
      </div>

      <div class="preferences-page__main">
        <PreferencesPanel
          v-if="preferencesData[activeCategory]"
          :settings="preferencesData[activeCategory]"
          :category="activeCategory"
          :profile-type="profileType"
          @save="handleSave"
        />
        <AccountSettings
          v-if="activeCategory === 'account' && profileType === 'OWNER'"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, inject } from 'vue';
import { useHead } from 'unhead';
import { ajax } from '../../lib/Ajax';
import CIcon from '@/components/c-icon.vue';
import PreferencesPanel from './preferences/PreferencesPanel.tsx';
import AccountSettings from './preferences/AccountSettings.tsx';

const SiteSettings = inject('SiteSettings');
const i18n = inject('I18n');
const currentUser = inject('currentUser');

const isLoading = ref(true);
const preferencesData = ref({});
const profileType = ref(null);
const activeCategory = ref(null);

const categories = computed(() => Object.keys(preferencesData.value));

const getCategoryIcon = (cat) => {
  const iconMap = {
    notifications: 'bell',
    account: 'user',
  };
  return iconMap[cat] || 'settings';
};

const fetchPreferences = async () => {
  try {
    const response = await ajax.get('/user/preferences.json');
    preferencesData.value = response.data.preferences;
    profileType.value = response.data.profile_type;

    if (categories.value.length > 0) {
      activeCategory.value = categories.value[0];
    }
  } catch (error) {
    console.error('Failed to load preferences:', error);
  } finally {
    isLoading.value = false;
  }
};

const handleSave = async (data) => {
  try {
    await ajax.put('/user/preferences.json', { preferences: data });
    return { success: true };
  } catch (error) {
    console.error('Failed to save preferences:', error);
    return { success: false, error: error.response?.data?.errors };
  }
};

onMounted(() => {
  fetchPreferences();
});

useHead({
  title: computed(() => `Preferencias | ${SiteSettings?.site_name || 'CinelarTV'}`),
  meta: [
    {
      name: 'description',
      content: 'Gestiona tus preferencias de usuario',
    },
  ],
});
</script>
