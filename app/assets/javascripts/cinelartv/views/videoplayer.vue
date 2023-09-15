<template>
  <div class="video-player-container" v-if="data">
    <div class="video-player">
      <video ref="videoPlayerRef" id="ctv-player" controls preload="auto"
        class="video-js vjs-default-skin vjs-big-play-centered relative">
      </video>
      <div class="ctv-overlay" ref="vplayerOverlay">
        <section class="back-button">
          <router-link :to="`/contents/${data.content.id}`">
            <c-button icon="chevron-left">{{ $t('js.video_player.back') }}</c-button>
          </router-link>
        </section>
        <section class="video-info">
          <h1 class="video-title">
            {{ data.content?.title }}
          </h1>
          <span class="video-episode" v-if="data.episode">
            {{ data.season.title }} - {{ data.episode.title }}
          </span>
        </section>
        <section class="video-controls">
          <c-icon-button class="video-control" icon="rotate-ccw" @click="seekBy(-10)" />
          <c-icon-button class="video-control" :icon="isPlaying ? 'pause' : 'play'" @click="togglePlayPause" />
          <c-icon-button class="video-control" icon="rotate-cw" @click="seekBy(10)" />
        </section>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeMount, onBeforeUnmount, inject } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ajax } from '../lib/axios-setup';
import videojs from 'video.js';
import 'video.js/dist/video-js.css'; // Importar estilos de Video.js

const SiteSettings = inject('SiteSettings');
const currentUser = inject('currentUser');
const i18n = inject('I18n');

const data = ref(null);
const videoSource = ref(null);
const videoPlayer = ref(null);
const vplayerOverlay = ref(null);
const userActive = ref(false);
const isPlaying = ref(false);
const lastDataSent = ref(null);
const currentPlayback = ref({
  currentTime: 0,
  duration: 0
});


const videoPlayerRef = ref();

const route = useRoute();
const router = useRouter();
const videoId = route.params.id;
const episodeId = route.params.episodeId;

const fetchData = async () => {
  try {
    let url = '';
    if (episodeId) {
      url = `/watch/${videoId}/${episodeId}.json`;
    } else {
      url = `/watch/${videoId}.json`;
    }
    const response = await ajax.get(url);
    data.value = response.data.data;
    if (data.value.content.content_type === 'MOVIE') {
      videoSource.value = data.value.content.url;
    } else {
      if (data.value.content.content_type === 'TV_SHOW' && !(route.params.episodeId || data.value.episode.id)) {
        let episodeId = data.value.continue_watching.episode_id || data.value.episode.id;
        router.replace(`/watch/${videoId}/${episodeId}`); // Agregar episodeId a la URL si es un programa de televisión
      }
      videoSource.value = data.value.episode.url;
    }
  } catch (error) {
    console.error(error);
    toast.error('Error al cargar el video.');
  }
};

const getVideoType = (url) => {
  const extension = url.split('.').pop();
  console.log(extension);
  switch (extension) {
    case 'mp4':
      return 'video/mp4';
    case 'm3u8':
      return 'application/x-mpegURL';
      return 'application/x-mpegurl';
    default:
      return 'video/mp4';
  }
}

onMounted(async () => {
  document.body.classList.add('video-player');
  await fetchData();

  videoPlayer.value = videojs(videoPlayerRef.value, {
    autoplay: true,
    preload: 'auto',
    responsive: true,
    fill: true,
    experimentalSvgIcons: true,
    bigPlayButton: false,
    errorDisplay: false,
    controlBar: {
      playToggle: false,
      pictureInPictureToggle: false,
      // Vertical Volume Control
      volumePanel: {
        inline: false
      },
    },
    sources: [
      {
        src: videoSource.value,
        type: getVideoType(videoSource.value)
      }
    ]
  });





  const { progress, duration } = data.value.continue_watching;
  if (progress > 0) {
    if (!videoPlayer.value) return;
    videoPlayer.value.currentTime(progress);
  }

  //CTV Custom Overlay

  videoPlayer.value.el().appendChild(vplayerOverlay.value);


  videoPlayer.value.on('userinactive', () => {
    userActive.value = false;
  });

  videoPlayer.value.on('useractive', () => {
    userActive.value = true;

  });

  videoPlayer.value.on('play', () => {
    isPlaying.value = true;
  });

  videoPlayer.value.on('pause', () => {
    isPlaying.value = false;
  });

  console.log(videoPlayer.value);

  videoPlayer.value.on('timeupdate', async () => {
    currentPlayback.value.currentTime = videoPlayer.value?.currentTime();
    currentPlayback.value.duration = videoPlayer.value?.duration();
    if (Date.now() - lastDataSent.value > 5000) {
      lastDataSent.value = Date.now();
      if (videoPlayer.value.currentTime() > 1) {
        await sendCurrentPosition();
      }
    }
  });
});

onBeforeUnmount(() => {
  document.body.classList.remove('video-player');
  videoPlayer.value.dispose();
});

const togglePlayPause = () => {
  if (isPlaying.value) {
    videoPlayer.value.pause();
  } else {
    videoPlayer.value.play();
  }
};

const sendCurrentPosition = async () => {
  try {
    await ajax.put(`/watch/${videoId}/progress.json`, {
      progress: videoPlayer.value.currentTime(),
      duration: videoPlayer.value.duration(),
      episode_id: episodeId
    });
  } catch (error) {
    console.error(error);
  }
};

const seekBy = (seconds) => {
  videoPlayer.value.currentTime(videoPlayer.value.currentTime() + seconds);
};
</script>
