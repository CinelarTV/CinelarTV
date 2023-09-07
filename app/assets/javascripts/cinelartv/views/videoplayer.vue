<template>
  <div class="video-player-container" @mousemove="toggleOverlay" v-if="data">
    <video ref="ctvPlayer" class="ctv-player" controls muted>
      <source :src="data.content.url" type="video/mp4" />
    </video>

    <div class="ctv-overlay" :class="{ 'overlay--hidden': !showOverlay }" @dblclick="toggleFullscreen()">
      <section class="back-button">
        <router-link :to="`/contents/${data.content.id}`" @click="toggleFullscreen(true); ctvPlayer.value.pause()">
          <c-button icon="chevron-left">{{ $t('js.video_player.back') }}</c-button>
        </router-link>
      </section>
      <section class="video-info">
        <h1 class="video-title">
          {{ data.content.title }}
          <span class="video-episode" v-if="data.content.episode_number">
            {{ $t('js.video_player.episode') }} {{ data.content.episode_number }}
          </span>
        </h1>
        <p class="video-description">{{ videoDescription }}</p>
      </section>
      <section class="video-controls">
        <c-icon-button class="video-control" icon="rotate-ccw" @click="seekBy(-10)" />
        <c-icon-button class="video-control" :icon="isPlaying ? 'pause' : 'play'" @click="togglePlayPause" />
        <c-icon-button class="video-control" icon="rotate-cw" @click="seekBy(10)" />
      </section>
      <section class="video-progress">
        <input
          type="range"
          class="video-progress-bar"
          min="0"
          max="100"
          step="0.01"
          :value="(currentPlayback.currentTime / currentPlayback.duration) * 100"
          @input="seekTo(currentPlayback.duration * ($event.target.value / 100))"
        />
        <div class="progress-info">
          <span class="video-time">
            {{ formatTime(currentPlayback.currentTime) }} <span class="remaining-time">/ {{ formatTime(currentPlayback.duration) }}</span></span>
        </div>
      </section>
    </div>
  </div>
  <div v-else>
    <c-spinner />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import fluidPlayer from 'fluid-player';
import { useRoute } from 'vue-router';

const ctvPlayer = ref(null);
const showOverlay = ref(true);
const isPlaying = ref(false);
const isMuted = ref(false);
const lastDataSent = ref(null);
const route = useRoute();
const videoId = route.params.id;
const episodeId = route.query.episodeId;
const data = ref(null);
const autoHideOverlay = ref();
const fluidplayer = ref(null);
const currentPlayback = ref({
  currentTime: 0,
  duration: 0
});

const fetchData = async () => {
  try {
    const response = await axios.get(`/watch/${videoId}.json`);
    console.log(response.data);
    data.value = response.data.data;
  } catch (error) {
    console.error(error);
  }
};

onMounted(async () => {
  document.body.classList.add('video-player');
  await fetchData();

  const { progress, duration } = data.value.continue_watching;
  console.log('Progress:', progress);
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
    vastOptions: {
      adList: [],
      adCTAText: false,
      adCTATextPosition: ''
    }
  };

  fluidplayer.value = fluidPlayer(ctvPlayer.value, options);

  ctvPlayer.value.addEventListener('play', () => {
    isPlaying.value = true;
  });

  ctvPlayer.value.addEventListener('pause', () => {
    isPlaying.value = false;
  });

  ctvPlayer.value.addEventListener('timeupdate', async () => {
    currentPlayback.value.currentTime = ctvPlayer.value.currentTime;
    currentPlayback.value.duration = ctvPlayer.value.duration;
    if (Date.now() - lastDataSent.value > 5000) {
      lastDataSent.value = Date.now();
      if (ctvPlayer.value.currentTime > 1) {
        await sendCurrentPosition();
      }
    }
  });

  ctvPlayer.value.addEventListener('loadstart', () => {
    //console.log('loadstart');
  });

  ctvPlayer.value.addEventListener('canplay', () => {
    //console.log('canplay');
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
    await axios.put(`/watch/${videoId}/progress.json`, {
      progress: ctvPlayer.value.currentTime,
      duration: ctvPlayer.value.duration,
      episodeId: episodeId
    });
    console.log('[Continnum] Current position sent to server (Progress: ' + ctvPlayer.value.currentTime + ' / ' + ctvPlayer.value.duration + ')')
  } catch (error) {
    console.error(error);
  }
};

document.addEventListener('contextmenu', (e) => {
  e.preventDefault();
});

const toggleFullscreen = (exit = false) => {
  if (document.fullscreenElement) {
    document.exitFullscreen();
  } else {
    document.documentElement.requestFullscreen();
  }

  if (exit) {
    document.exitFullscreen();
  }
};

const formatTime = (time) => {
  const hours = Math.floor(time / 3600);
  const minutes = Math.floor((time - (hours * 3600)) / 60);
  const seconds = Math.floor(time - (hours * 3600) - (minutes * 60));
  const formattedTime = `${hours > 0 ? hours + ':' : ''}${minutes < 10 ? '0' + minutes : minutes}:${seconds < 10 ? '0' + seconds : seconds}`;
  return formattedTime;
};
</script>
