<template>
    <div class="live-tv-admin">
        <header class="live-tv-admin__hero">
            <div class="live-tv-admin__hero-copy">
                <h1 class="live-tv-admin__title">Live TV Manager</h1>
                <p class="live-tv-admin__subtitle">
                    Administra canales, streams y fuentes XMLTV desde un solo lugar.
                </p>
            </div>
            <c-button class="live-tv-admin__refresh-btn" @click="refreshAll"
                :loading="loadingChannels || loadingSources">
                Actualizar
            </c-button>
        </header>

        <section class="live-tv-admin__stats">
            <article class="live-tv-admin__stat-card">
                <span class="live-tv-admin__stat-label">Canales</span>
                <strong class="live-tv-admin__stat-value">{{ channels.length }}</strong>
            </article>
            <article class="live-tv-admin__stat-card">
                <span class="live-tv-admin__stat-label">Canales activos</span>
                <strong class="live-tv-admin__stat-value">{{ activeChannelsCount }}</strong>
            </article>
            <article class="live-tv-admin__stat-card">
                <span class="live-tv-admin__stat-label">Fuentes XMLTV</span>
                <strong class="live-tv-admin__stat-value">{{ sources.length }}</strong>
            </article>
            <article class="live-tv-admin__stat-card">
                <span class="live-tv-admin__stat-label">Fuentes activas</span>
                <strong class="live-tv-admin__stat-value">{{ activeSourcesCount }}</strong>
            </article>
        </section>

        <section class="live-tv-admin__card">
            <div class="live-tv-admin__section-header">
                <div>
                    <h2>Canales</h2>
                    <p>Configura streams, formato y orden de visualizacion. {{ channels.length }} total.</p>
                </div>
                <c-button @click="startCreateChannel">
                    <PlusIcon :size="16" />
                    Nuevo canal
                </c-button>
            </div>

            <form v-if="showChannelForm" class="live-tv-admin__form" @submit.prevent="saveChannel">
                <div class="live-tv-admin__form-grid">
                    <label class="live-tv-admin__field">
                        <span>Nombre</span>
                        <input v-model="channelForm.name" type="text" required />
                    </label>
                    <label class="live-tv-admin__field">
                        <span>Formato</span>
                        <select v-model="channelForm.stream_format" required>
                            <option v-for="format in streamFormats" :key="format" :value="format">{{ format }}</option>
                        </select>
                    </label>
                    <label class="live-tv-admin__field live-tv-admin__field--wide">
                        <span>Stream URL</span>
                        <input v-model="channelForm.stream_url" type="url" required />
                    </label>
                    <label class="live-tv-admin__field live-tv-admin__field--wide">
                        <span>Logo URL</span>
                        <input v-model="channelForm.logo_url" type="url" />
                    </label>
                    <label class="live-tv-admin__field">
                        <span>XMLTV Channel ID</span>
                        <input v-model="channelForm.xmltv_channel_id" type="text" />
                    </label>
                    <label class="live-tv-admin__field">
                        <span>Posicion</span>
                        <input v-model.number="channelForm.position" type="number" min="0" />
                    </label>
                    <label class="live-tv-admin__field live-tv-admin__field--wide">
                        <span>Descripcion</span>
                        <textarea v-model="channelForm.description" rows="3" />
                    </label>
                </div>

                <label class="live-tv-admin__toggle">
                    <input v-model="channelForm.is_active" type="checkbox" />
                    <span>Canal activo</span>
                </label>

                <div class="live-tv-admin__actions">
                    <c-button type="submit" :loading="savingChannel">
                        {{ channelForm.id ? 'Guardar cambios' : 'Crear canal' }}
                    </c-button>
                    <c-button type="button" @click="resetChannelForm">Cancelar</c-button>
                </div>
            </form>

            <div v-if="loadingChannels" class="live-tv-admin__loading">
                <c-spinner />
            </div>
            <div v-else-if="channels.length === 0" class="live-tv-admin__empty">
                Aun no hay canales. Crea el primero para empezar.
            </div>
            <draggable v-else v-model="channels" item-key="id" handle=".live-tv-admin__drag"
                ghost-class="live-tv-admin__ghost" @end="persistChannelOrder">
                <template #item="{ element }">
                    <article class="live-tv-admin__list-item">
                        <button type="button" class="live-tv-admin__drag" aria-label="Reordenar canal">::</button>
                        <img v-if="element.logo_url" class="live-tv-admin__logo" :src="element.logo_url"
                            :alt="element.name" />
                        <div class="live-tv-admin__item-main">
                            <div class="live-tv-admin__item-title">
                                <strong>{{ element.name }}</strong>
                                <span class="live-tv-admin__badge"
                                    :class="element.is_active ? 'is-active' : 'is-inactive'">
                                    {{ element.is_active ? 'Activo' : 'Inactivo' }}
                                </span>
                            </div>
                            <p>{{ element.stream_url }}</p>
                        </div>
                        <div class="live-tv-admin__item-actions">
                            <button type="button" @click="editChannel(element)">
                                <PencilIcon :size="14" />
                                Editar
                            </button>
                            <button type="button" class="is-danger" @click="deleteChannel(element)">
                                <Trash2Icon :size="14" />
                                Eliminar
                            </button>
                        </div>
                    </article>
                </template>
            </draggable>
        </section>

        <section class="live-tv-admin__card">
            <div class="live-tv-admin__section-header">
                <div>
                    <h2>Fuentes XMLTV</h2>
                    <p>Conecta guias EPG y ejecuta fetch/parsing manual cuando lo necesites. {{ sources.length }} total.
                    </p>
                </div>
                <c-button @click="startCreateSource">
                    <PlusIcon :size="16" />
                    Nueva fuente
                </c-button>
            </div>

            <form v-if="showSourceForm" class="live-tv-admin__form" @submit.prevent="saveSource">
                <div class="live-tv-admin__form-grid">
                    <label class="live-tv-admin__field">
                        <span>Nombre</span>
                        <input v-model="sourceForm.name" type="text" required />
                    </label>
                    <label class="live-tv-admin__field live-tv-admin__field--wide">
                        <span>URL XMLTV</span>
                        <input v-model="sourceForm.url" type="url" required />
                    </label>
                </div>

                <label class="live-tv-admin__toggle">
                    <input v-model="sourceForm.is_active" type="checkbox" />
                    <span>Fuente activa</span>
                </label>

                <div class="live-tv-admin__actions">
                    <c-button type="submit" :loading="savingSource">
                        {{ sourceForm.id ? 'Guardar cambios' : 'Crear fuente' }}
                    </c-button>
                    <c-button type="button" :disabled="!!sourceForm.id" @click="saveSource(true)">
                        Crear y ejecutar fetch
                    </c-button>
                    <c-button type="button" @click="resetSourceForm">Cancelar</c-button>
                </div>
            </form>

            <div v-if="loadingSources" class="live-tv-admin__loading">
                <c-spinner />
            </div>
            <div v-else-if="sources.length === 0" class="live-tv-admin__empty">
                Aun no hay fuentes XMLTV configuradas.
            </div>
            <div v-else class="live-tv-admin__source-list">
                <article v-for="source in sources" :key="source.id" class="live-tv-admin__source-item">
                    <div class="live-tv-admin__item-main">
                        <div class="live-tv-admin__item-title">
                            <strong>{{ source.name }}</strong>
                            <span class="live-tv-admin__badge" :class="source.is_active ? 'is-active' : 'is-inactive'">
                                {{ source.is_active ? 'Activa' : 'Inactiva' }}
                            </span>
                        </div>
                        <p>{{ source.url }}</p>
                        <small>
                            Ultimo fetch: {{ formatDate(source.last_fetched_at) }}
                            · Ultimo parse: {{ formatDate(source.last_parsed_at) }}
                        </small>
                    </div>
                    <div class="live-tv-admin__item-actions">
                        <button type="button" @click="fetchSource(source)">Fetch</button>
                        <button type="button" @click="editSource(source)">
                            <PencilIcon :size="14" />
                            Editar
                        </button>
                        <button type="button" class="is-danger" @click="deleteSource(source)">
                            <Trash2Icon :size="14" />
                            Eliminar
                        </button>
                    </div>
                </article>
            </div>
        </section>
    </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import draggable from 'vuedraggable';
import { toast } from 'vue3-toastify';
import { PlusIcon, PencilIcon, Trash2Icon } from 'lucide-vue-next';
import { ajax } from '../../lib/Ajax';

const streamFormats = ['hls', 'dash', 'rtmp', 'external'];

const loadingChannels = ref(true);
const loadingSources = ref(true);
const savingChannel = ref(false);
const savingSource = ref(false);

const channels = ref([]);
const sources = ref([]);

const showChannelForm = ref(false);
const showSourceForm = ref(false);

const channelForm = ref(defaultChannelForm());
const sourceForm = ref(defaultSourceForm());

const activeChannelsCount = computed(() => channels.value.filter((channel) => channel.is_active).length);
const activeSourcesCount = computed(() => sources.value.filter((source) => source.is_active).length);

function defaultChannelForm() {
    return {
        id: null,
        name: '',
        description: '',
        logo_url: '',
        stream_url: '',
        stream_format: 'hls',
        is_active: true,
        position: 0,
        xmltv_channel_id: '',
    };
}

function defaultSourceForm() {
    return {
        id: null,
        name: '',
        url: '',
        is_active: true,
    };
}

function startCreateChannel() {
    showChannelForm.value = true;
    channelForm.value = defaultChannelForm();
}

function editChannel(channel) {
    showChannelForm.value = true;
    channelForm.value = {
        id: channel.id,
        name: channel.name || '',
        description: channel.description || '',
        logo_url: channel.logo_url || '',
        stream_url: channel.stream_url || '',
        stream_format: channel.stream_format || 'hls',
        is_active: !!channel.is_active,
        position: Number.isInteger(channel.position) ? channel.position : 0,
        xmltv_channel_id: channel.xmltv_channel_id || '',
    };
}

function resetChannelForm() {
    showChannelForm.value = false;
    channelForm.value = defaultChannelForm();
}

function startCreateSource() {
    showSourceForm.value = true;
    sourceForm.value = defaultSourceForm();
}

function editSource(source) {
    showSourceForm.value = true;
    sourceForm.value = {
        id: source.id,
        name: source.name || '',
        url: source.url || '',
        is_active: !!source.is_active,
    };
}

function resetSourceForm() {
    showSourceForm.value = false;
    sourceForm.value = defaultSourceForm();
}

async function fetchChannels() {
    loadingChannels.value = true;
    try {
        const response = await ajax.get('/admin/live_tv_channels.json');
        channels.value = response.data.live_tv_channels || [];
    } catch (error) {
        toast.error('No se pudieron cargar los canales de Live TV');
        console.error(error);
    } finally {
        loadingChannels.value = false;
    }
}

async function fetchSources() {
    loadingSources.value = true;
    try {
        const response = await ajax.get('/admin/xmltv_sources.json');
        sources.value = response.data.xmltv_sources || [];
    } catch (error) {
        toast.error('No se pudieron cargar las fuentes XMLTV');
        console.error(error);
    } finally {
        loadingSources.value = false;
    }
}

async function refreshAll() {
    await Promise.all([fetchChannels(), fetchSources()]);
}

async function saveChannel() {
    savingChannel.value = true;
    const payload = {
        live_tv_channel: {
            name: channelForm.value.name,
            description: channelForm.value.description,
            logo_url: channelForm.value.logo_url,
            stream_url: channelForm.value.stream_url,
            stream_format: channelForm.value.stream_format,
            is_active: channelForm.value.is_active,
            position: channelForm.value.position,
            xmltv_channel_id: channelForm.value.xmltv_channel_id,
        },
    };

    try {
        if (channelForm.value.id) {
            await ajax.put(`/admin/live_tv_channels/${channelForm.value.id}.json`, payload);
            toast.success('Canal actualizado');
        } else {
            await ajax.post('/admin/live_tv_channels.json', payload);
            toast.success('Canal creado');
        }
        resetChannelForm();
        await fetchChannels();
    } catch (error) {
        toast.error('No se pudo guardar el canal');
        console.error(error);
    } finally {
        savingChannel.value = false;
    }
}

async function deleteChannel(channel) {
    if (!window.confirm(`Eliminar el canal ${channel.name}?`)) {
        return;
    }

    try {
        await ajax.delete(`/admin/live_tv_channels/${channel.id}.json`);
        toast.success('Canal eliminado');
        await fetchChannels();
    } catch (error) {
        toast.error('No se pudo eliminar el canal');
        console.error(error);
    }
}

async function persistChannelOrder() {
    const channelIds = channels.value.map((channel) => channel.id);
    try {
        await ajax.post('/admin/live_tv_channels/reorder.json', { channel_ids: channelIds });
        toast.success('Orden actualizado');
        await fetchChannels();
    } catch (error) {
        toast.error('No se pudo guardar el orden de canales');
        console.error(error);
    }
}

async function saveSource(fetchNow = false) {
    savingSource.value = true;
    const payload = {
        xmltv_source: {
            name: sourceForm.value.name,
            url: sourceForm.value.url,
            is_active: sourceForm.value.is_active,
        },
        fetch_now: fetchNow,
    };

    try {
        if (sourceForm.value.id) {
            await ajax.put(`/admin/xmltv_sources/${sourceForm.value.id}.json`, payload);
            toast.success('Fuente actualizada');
        } else {
            await ajax.post('/admin/xmltv_sources.json', payload);
            toast.success(fetchNow ? 'Fuente creada y fetch en cola' : 'Fuente creada');
        }
        resetSourceForm();
        await fetchSources();
    } catch (error) {
        toast.error('No se pudo guardar la fuente XMLTV');
        console.error(error);
    } finally {
        savingSource.value = false;
    }
}

async function deleteSource(source) {
    if (!window.confirm(`Eliminar la fuente ${source.name}?`)) {
        return;
    }

    try {
        await ajax.delete(`/admin/xmltv_sources/${source.id}.json`);
        toast.success('Fuente eliminada');
        await fetchSources();
    } catch (error) {
        toast.error('No se pudo eliminar la fuente XMLTV');
        console.error(error);
    }
}

async function fetchSource(source) {
    try {
        await ajax.post(`/admin/xmltv_sources/${source.id}/fetch.json`);
        toast.success('Fetch XMLTV encolado');
        await fetchSources();
    } catch (error) {
        toast.error('No se pudo ejecutar el fetch XMLTV');
        console.error(error);
    }
}

function formatDate(value) {
    if (!value) {
        return 'Nunca';
    }

    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
        return 'Desconocido';
    }

    return date.toLocaleString();
}

onMounted(() => {
    refreshAll();
});
</script>