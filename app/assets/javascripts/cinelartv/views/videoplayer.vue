<template>
  <div class="video-player-container" @mousemove="toggleOverlay" v-if="data">
    <video ref="ctvPlayer" class="ctv-player" controls muted>
      <source :src="videoSource" type="video/mp4" />
    </video>

    <div class="ctv-overlay" :class="{ 'overlay--hidden': !showOverlay }" @dblclick="toggleFullscreen()">
      <section class="back-button">
        <router-link :to="`/contents/${data.content.id}`">
          <c-button icon="chevron-left">{{ $t('js.video_player.back') }}</c-button>
        </router-link>
      </section>
      <section class="video-info">
        <h1 class="video-title">
          {{ data.content.title }}
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
      <section class="video-progress">
        <input type="range" class="video-progress-bar" min="0" max="100" step="0.01"
          :value="(currentPlayback.currentTime / currentPlayback.duration) * 100"
          @input="seekTo(currentPlayback.duration * ($event.target.value / 100))" />
        <div class="progress-info">
          <span class="video-time">
            {{ formatTime(currentPlayback.currentTime) }} <span class="remaining-time">/ {{
              formatTime(currentPlayback.duration) }}</span></span>
        </div>
      </section>
    </div>
  </div>
  <div v-else>
    <c-spinner />
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeMount, onBeforeUnmount } from 'vue';
import fluidPlayer from 'fluid-player';
import { useRoute, useRouter } from 'vue-router';
import { toast } from 'vue3-toastify';
import { ajax } from '../lib/axios-setup';

const ctvPlayer = ref(null);
const showOverlay = ref(true);
const isPlaying = ref(false);
const isMuted = ref(false);
const lastDataSent = ref(null);
const route = useRoute();
const router = useRouter();
const videoId = route.params.id;
const episodeId = route.params.episodeId;
const data = ref(null);
const autoHideOverlay = ref();
const fluidplayer = ref(null);
const videoSource = ref('');
const currentPlayback = ref({
  currentTime: 0,
  duration: 0
});

const fetchData = async () => {
  try {
    let url = ''
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
        router.replace(`/watch/${videoId}/${episodeId}`) // Add episodeId to URL if it's a tv show
      }
      videoSource.value = data.value.episode.url;
    }



  } catch (error) {
    console.error(error);
    toast.error('Error al cargar el video.');
  }
};

onMounted(async () => {
  document.body.classList.add('video-player');
  await fetchData();

  if (data.value.content.content_type === 'MOVIE' && route.params.episodeId) {
    router.replace(`/watch/${videoId}`) // Remove episodeId from URL if it's a movie
  }

  const { progress, duration } = data.value.continue_watching;
  if (progress > 0) {
    ctvPlayer.value.currentTime = progress;
  }

  const options = {
    layoutControls: {
      miniPlayer: {
        enabled: false
      },
      controlBar: {
        autoHideTimeout: 3,
        animated: true,
        autoHide: true
      },
      htmlOnPauseBlock: {
        html: null,
        height: '',
        width: null
      },
      autoPlay: true,
      mute: false,
      allowTheatre: false,
      playPauseAnimation: true,
      playbackRateEnabled: false,
      allowDownload: false,
      playButtonShowing: true,
      fillToContainer: false,
      posterImage: ''
    },
  };

  fluidplayer.value = fluidPlayer(ctvPlayer.value, options);

  ctvPlayer.value.addEventListener('play', () => {
    isPlaying.value = true;
  });

  ctvPlayer.value.addEventListener('pause', () => {
    isPlaying.value = false;
  });

  ctvPlayer.value.addEventListener('timeupdate', async () => {
    currentPlayback.value.currentTime = ctvPlayer.value?.currentTime;
    currentPlayback.value.duration = ctvPlayer.value?.duration;
    if (Date.now() - lastDataSent.value > 5000) {
      lastDataSent.value = Date.now();
      if (ctvPlayer.value.currentTime > 1) {
        await sendCurrentPosition();
      }
    }
  });


  ctvPlayer.value.addEventListener('waiting', () => {
    console.log('waiting');
  });

  ctvPlayer.value.addEventListener('loadstart', () => {
    //console.log('loadstart');
  });

  ctvPlayer.value.addEventListener('canplay', () => {
    //console.log('canplay');
  });

  ctvPlayer.value.addEventListener('error', (e) => {
    console.error('Error:', e);
    alert('Error al reproducir el video.');
  });

  ctvPlayer.value.removeAttribute('muted');
  ctvPlayer.value.muted = false;



  toggleOverlay();
});

const seekTo = (time) => {
  ctvPlayer.value.currentTime = time;
  currentPlayback.value.currentTime = time;
  if (ctvPlayer.value.paused) {
    ctvPlayer.value.play();
  }
};

const seekBy = (seconds) => {
  seekTo(currentPlayback.value.currentTime + seconds);
};

const togglePlayPause = () => {
  if (ctvPlayer.value.paused) {
    ctvPlayer.value.play();
  } else {
    ctvPlayer.value.pause();
  }
};

const toggleOverlay = (click = false) => {
  if (!showOverlay.value) {
    showOverlay.value = true;
    autoHideOverlay.value = setTimeout(() => {
      showOverlay.value = false;
    }, 3000);
  } else {
    clearTimeout(autoHideOverlay.value);
    autoHideOverlay.value = setTimeout(() => {
      showOverlay.value = false;
    }, 3000);
  }
};

const sendCurrentPosition = async () => {
  try {
    await ajax.put(`/watch/${videoId}/progress.json`, {
      progress: ctvPlayer.value.currentTime,
      duration: ctvPlayer.value.duration,
      episode_id: episodeId
    });
  } catch (error) {
    console.error(error);
  }
};

document.addEventListener('contextmenu', (e) => {
  e.preventDefault();
});

const toggleFullscreen = (exit = false) => {
  if (document.fullscreenElement) {
    document.exitFullscreen().catch((error) => {
      // Do nothing
    });
  } else {
    document.documentElement.requestFullscreen().catch((error) => {
      // Do nothing
    });
  }

  if (exit) {
    document.exitFullscreen().catch((error) => {
      // Do nothing
    });
  }
};

const formatTime = (time) => {
  const hours = Math.floor(time / 3600);
  const minutes = Math.floor((time - (hours * 3600)) / 60);
  const seconds = Math.floor(time - (hours * 3600) - (minutes * 60));
  const formattedTime = `${hours > 0 ? hours + ':' : ''}${minutes < 10 ? '0' + minutes : minutes}:${seconds < 10 ? '0' + seconds : seconds}`;
  return formattedTime;
};

onBeforeUnmount(async () => {
  data.value = null;
  // Remove event listeners
  ctvPlayer.value.removeEventListener('timeupdate', () => { });


  document.body.classList.remove('video-player')
  ctvPlayer.value.pause();
  ctvPlayer.value = null;
  fluidplayer.value.destroy();
  document.exitFullscreen().catch((error) => {
    // Do nothing
  });
  await new Promise((resolve) => setTimeout(resolve, 1000));
});
</script>
