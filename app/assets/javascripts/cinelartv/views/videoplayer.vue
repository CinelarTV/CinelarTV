<template>
  <div class="video-player-container" v-if="data">
    <div class="video-player" :class="userActive ? 'user-active' : 'user-inactive'">
      <video ref="videoPlayerRef" id="ctv-player" controls preload="auto"
        class="video-js vjs-default-skin vjs-big-play-centered relative">
      </video>
      <div class="ctv-overlay" ref="vplayerOverlay" @click="handleOverlayClick" @dblclick="toggleFullscreen">
        <section class="back-button">
          <router-link :to="`/contents/${data.content.id}`" class="button c-button">
            <c-icon icon="chevron-left" />
            {{ $t('js.video_player.back') }}
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
      <section class="skippers" :class="showSkipIntro ? '' : 'skippers-hidden'" v-if="data.episode" ref="skippersRef">
        <c-button class="skip-intro-button" icon="fast-forward" @click="skipIntro">
          {{ $t('js.video_player.skip_intro') }}
        </c-button>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeMount, onBeforeUnmount, inject, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ajax } from '../lib/Ajax';
import videojs from 'video.js';
import 'video.js/dist/video-js.css'; // Importar estilos de Video.js
import chromecast from '@silvermine/videojs-chromecast'
import { useHead } from 'unhead';

const SiteSettings = inject('SiteSettings');
const currentUser = inject('currentUser');
const i18n = inject('I18n');
const isMobile = inject('isMobile');

const data = ref(null);
const videoSource = ref(null);
const videoPlayer = ref(null);
const vplayerOverlay = ref(null);
const userActive = ref(true);
const isPlaying = ref(false);
const loading = ref(true);
const lastDataSent = ref(null);
const fullscreen = ref(false);
const currentPlayback = ref({
  currentTime: 0,
  duration: 0
});

const showSkipIntro = ref(false);


const videoPlayerRef = ref();
const skippersRef = ref();

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

    // Redireccionar si es un programa de televisión sin episodio seleccionado
    if (
      data.value.content.content_type === 'TVSHOW' &&
      !(route.params.episodeId || data.value.episode?.id)
    ) {
      // Obtener el primer episodio de la temporada
      const firstEpisode = data.value.season.episodes[0];

      if (firstEpisode) {
        const episodeId = firstEpisode.id;
        console.log('Redireccionando a:', `/watch/${videoId}/${episodeId}`);
        return router.replace(`/watch/${videoId}/${episodeId}`); // Agregar episodeId a la URL si es un programa de televisión
      }
    }
    else if (!route.params.episodeId && data.value.episode?.id) {
      return router.replace(`/watch/${videoId}/${data.value.episode.id}`);
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

  useHead({
    title: data.value?.content?.title,
  });


  videoPlayer.value = videojs(videoPlayerRef.value, {
    autoplay: true,
    preload: 'auto',
    responsive: true,
    fill: true,
    inactivityTimeout: route.query.debug ? 0 : 3000,
    poster: data.value.content.banner,
    experimentalSvgIcons: true,
    bigPlayButton: false,
    errorDisplay: false,
    userActions: {
      hotkeys: true
    },
    controlBar: {
      playToggle: false,
      pictureInPictureToggle: false,
      volumePanel: false,
      fullscreenToggle: false
    },
    sources: data.value.sources.map((source) => {
      return {
        src: source.url,
        type: getVideoType(source.url)
      }
    })
  });


  // set user inactive timeout to 5 seconds


  const { progress, duration } = data.value.continue_watching;
  if (progress > 0) {
    if (!videoPlayer.value) return;
    videoPlayer.value.currentTime(progress);
  }



  // Alway show control bar (For testing purposes)



  //CTV Custom Overlay

  videoPlayer.value.el().appendChild(vplayerOverlay.value);

  if (skippersRef.value) {
    videoPlayer.value.el().appendChild(skippersRef.value);
    // Only episode videos have skippers
  }

  // Add custom button to control bar for admin users

  if (currentUser.admin) {
    videoPlayer.value.controlBar.addChild('button', {
      text: 'Admin',
      el: videoPlayer.value.controlBar.el().insertBefore(document.createElement('button'), videoPlayer.value.controlBar.el().firstChild),
      onClick: () => {
        router.push(`/admin/contents/${data.value.content.id}/edit`);
      }
    });
  }


  // Set userinactive timeout to 0 to always show controls



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

  videoPlayer.value.on('waiting', () => {
    loading.value = true;
  });

  videoPlayer.value.on('playing', () => {
    loading.value = false;
  });


  videoPlayer.value.on('fullscreenchange', () => {
    fullscreen.value = !fullscreen.value;
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

  // Expose videojs player to the window object because @silvermine/videojs-chromecast plugin needs it
  window.videojs = videoPlayer.value;

  // Register videojs-chromecast plugin

  //chromecast(videoPlayer.value)

  if (isMobile) {
    try {
      videoPlayer.value.requestFullscreen();
      if (screen && screen.orientation && screen.orientation.lock) {
        screen.orientation.lock('landscape-primary');
      } else if (window.screen && window.screen.lockOrientation) {
        window.screen.lockOrientation('landscape-primary');
      } else {
        console.warn('El navegador no admite la API de bloqueo de orientación.');
      }
    } catch (error) {
      console.error('Error al cambiar la orientación:', error);
    }
  }


});

watch(currentPlayback.value, (newVal, oldVal) => {
  if (data.value.episode) {
    if (data.value.episode?.skip_intro_start && data.value.episode?.skip_intro_end) {
      if (newVal.currentTime >= data.value.episode.skip_intro_start && newVal.currentTime <= data.value.episode.skip_intro_end) {
        showSkipIntro.value = true;
      } else {
        showSkipIntro.value = false;
      }
    }
  }
});

onBeforeUnmount(() => {
  document.body.classList.remove('video-player');
  if (videoPlayer.value.isFullscreen()) {
    videoPlayer.value.exitFullscreen();
    try {
      screen.orientation.unlock();
    } catch (error) {
      // Do nothing, this is not supported on desktop
    }
  }
  videoPlayer.value.dispose();
  videoPlayer.value = null;
});



const handleOverlayClick = (e) => {
  if (e.target === vplayerOverlay.value) {
    togglePlayPause();
  }
};

const toggleFullscreen = (e) => {
  if (e.target === vplayerOverlay.value) {
    if (videoPlayer.value.isFullscreen()) {
      videoPlayer.value.exitFullscreen();
    } else {
      videoPlayer.value.requestFullscreen();
    }
  }
};

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

const skipIntro = () => {
  videoPlayer.value.currentTime(data.value.episode.skip_intro_end);
};

const seekBy = (seconds) => {
  videoPlayer.value.currentTime(videoPlayer.value.currentTime() + seconds);
};


</script>
../lib/ajax