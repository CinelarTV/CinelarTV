<template>
  <div class="video-player-container" @click="toggleOverlay" @mousemove="toggleOverlay" v-if="data">
    <video ref="ctvPlayer" class="ctv-player" controls muted>
      <source :src="data.content.url" type="video/mp4" />
    </video>

    <div class="ctv-overlay" :class="{ 'overlay--hidden': !showOverlay }" @dblclick="toggleFullscreen">
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
        <button class="video-control" @click="togglePlayPause">
          play
        </button>
        <button class="video-control" @click="toggleMute">
          <i class="fas fa-volume-up" v-if="!isMuted"></i>
          <i class="fas fa-volume-mute" v-else></i>
        </button>
        <button class="video-control" @click="toggleFullscreen">
          <i class="fas fa-expand"></i>
        </button>
      </section>

      <section class="video-progress">

        <input type="range" class="video-progress-bar" min="0" max="100" step="0.01"
          :value="currentPlayback.currentTime / 100" @input="seekTo($event.target.value * 100)" />
        <div class="progress-info">
          <span class="video-time">
            {{ formatTime(currentPlayback.currentTime) }}
            <span class="remaining-time" v-if="currentPlayback.duration">
              / {{ formatTime(currentPlayback.duration) }}
            </span>
          </span>
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
const autoHideOverlay = ref()
const fluidplayer = ref(null)
const currentPlayback = ref({
  currentTime: 0,
  duration: 0
})

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
    "layoutControls": {
      miniPlayer: {
        enabled: false
      },
      "controlBar": { "autoHideTimeout": 3, "animated": true, "autoHide": true },
      "htmlOnPauseBlock": { "html": null, "height": "", "width": null }, "autoPlay": true, "mute": false, "allowTheatre": false, "playPauseAnimation": true, "playbackRateEnabled": false, "allowDownload": false, "playButtonShowing": true, "fillToContainer": false, "posterImage": ""
    }, "vastOptions": { "adList": [], "adCTAText": false, "adCTATextPosition": "" },

  }

  fluidplayer.value = fluidPlayer(ctvPlayer.value, options);


  ctvPlayer.value.addEventListener('play', () => {
    isPlaying.value = true;
  });

  ctvPlayer.value.addEventListener('pause', () => {
    isPlaying.value = false;
  });

  // On position change, send time to server (Every 5 seconds to avoid overloading the server)
  ctvPlayer.value.addEventListener('timeupdate', async () => {
    currentPlayback.value.currentTime = ctvPlayer.value.currentTime
    currentPlayback.value.duration = ctvPlayer.value.duration
    if (Date.now() - lastDataSent.value > 5000) {
      lastDataSent.value = Date.now();
      if (ctvPlayer.value.currentTime > 1) { // Don't send data if the video is just starting
        await sendCurrentPosition();
      }
    }
  });

  // Remove muted attribute on load
  ctvPlayer.value.removeAttribute('muted');
  ctvPlayer.value.muted = false;

  toggleOverlay(); // Hide overlay on load
});

const seekTo = (time) => {
  ctvPlayer.value.currentTime = time;
  currentPlayback.value.currentTime = time
  if (ctvPlayer.value.paused) {
    ctvPlayer.value.play();
  }
};

const toggleOverlay = () => {
  if (!showOverlay.value) {
    // Mostrar overlay y configurar el temporizador para ocultarlo después de 3 segundos
    showOverlay.value = true;
    autoHideOverlay.value = setTimeout(() => {
      showOverlay.value = false;
    }, 3000);
  } else {
    // Si ya está visible, simplemente reiniciar el temporizador
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

const toggleFullscreen = () => {
  // We need to fullscreen all the document, not just the video element (Because of the custom overlay)
  document.fullscreenElement ? document.exitFullscreen() : document.documentElement.requestFullscreen();
};


const togglePlayPause = () => {
  if (ctvPlayer.value) {
    if (isPlaying.value) {
      ctvPlayer.value.pause();
    } else {
      ctvPlayer.value.play();
    }
    isPlaying.value = !isPlaying.value;
  }
};

const toggleMute = () => {
  if (ctvPlayer.value) {
    ctvPlayer.value.muted = !ctvPlayer.value.muted;
    isMuted.value = ctvPlayer.value.muted;
  }
};

const formatTime = (time) => {
  const hours = Math.floor(time / 3600);
  const minutes = Math.floor((time - (hours * 3600)) / 60);
  const seconds = Math.floor(time - (hours * 3600) - (minutes * 60));

  const formattedTime = `${hours > 0 ? hours + ':' : ''}${minutes < 10 ? '0' + minutes : minutes}:${seconds < 10 ? '0' + seconds : seconds}`;
  return formattedTime;
};


// ... (código existente)
</script>

<style>
/* Estilos para el overlay personalizado */
.ctv-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.7);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: white;
  opacity: 1;
  /* Inicialmente visible */
  transition: opacity 0.3s ease;
  /* Efecto de desvanecimiento */
}

.ctv-overlay .video-info {
  position: absolute;
  padding: 20px;
  margin: 0 auto;
  top: 0;
}

.ctv-overlay .video-info .video-title {
  font-size: 24px;
  margin-bottom: 10px;
  font-weight: 600;
}



.overlay--hidden {
  opacity: 0;
}

.video-progress {
  width: 100%;
  text-align: center;
  position: absolute;
  bottom: 32px;
  padding-left: 50px;
  padding-right: 50px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.video-progress-bar {
  width: 100%;
  height: 3px;
  background-color: #333;
  cursor: pointer;
}

.progress-info {
  margin-top: 10px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: left;
}

.remaining-time {
  opacity: 0.5;
  font-weight: 600;
}

.progress-popup {
  position: absolute;
  top: -30px;
  background-color: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 5px 10px;
  border-radius: 5px;
  font-size: 14px;
  white-space: nowrap;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.3s ease;
  transform: translateX(-50%);
}

.buffer-progress {
  height: 100%;
  background-color: rgba(255, 255, 255, 0.3);
  position: absolute;
  top: 0;
  left: 0;
}

/* Mostrar el popup al pasar el mouse sobre la barra de progreso */
.video-progress:hover .progress-popup {
  opacity: 1;
}


@keyframes fadeOut {
  from {
    opacity: 1;
  }

  to {
    opacity: 0;
  }
}
</style>
