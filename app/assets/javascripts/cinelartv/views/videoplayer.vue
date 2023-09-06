<template>
  <div class="video-player-container" @click="toggleOverlay" @mousemove="toggleOverlay" v-if="data">
    <video ref="ctvPlayer" class="ctv-player" controls muted>
      <source :src="data.content.url" type="video/mp4" />
    </video>

    <div class="custom-overlay" :class="{ 'overlay--hidden': !showOverlay }" @dblclick="toggleFullscreen">
      <p>Contenido del overlay personalizado</p>
      <button @click="togglePlayPause">Reproducir/Pausar</button>
      <button @click="toggleMute">Activar/Silenciar</button>
    </div>
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
const videoTitle = 'Video Title';
const videoDescription = 'Video Description';
const lastDataSent = ref(null);
const route = useRoute();
const videoId = route.params.id;
const episodeId = route.query.episodeId;
const data = ref(null);
const autoHideOverlay = ref()
const fluidplayer = ref(null)

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

// ... (código existente)
</script>

<style>
/* Estilos para el overlay personalizado */
.custom-overlay {
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

.custom-overlay p {
  font-size: 18px;
  margin-bottom: 10px;
}

.custom-overlay button {
  background-color: #007bff;
  color: white;
  padding: 10px 20px;
  border: none;
  cursor: pointer;
}

.custom-overlay button:hover {
  background-color: #0056b3;
}

.overlay--hidden {
  opacity: 0;
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
