<template>
  <div class="video-player-container">
    <video ref="myVideoPlayer" class="fluid-video" controls muted v-if="data">
      <source :src="data.content.url"
        type="video/mp4" />
    </video>

  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import fluidPlayer from 'fluid-player';
import { useRoute } from 'vue-router';

const myVideoPlayer = ref(null);
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


const fetchData = async () => {
  try {
    const response = await axios.get(`/watch/${videoId}.json`);
    console.log(response.data);
    data.value = response.data.data;
    const { progress, duration } = response.data.data.continue_watching;
    if (progress > 0) {
      myVideoPlayer.value.currentTime = progress;
    }
  } catch (error) {
    console.error(error);
  }
};

onMounted(async () => {
  document.body.classList.add('video-player');
  await fetchData();

  const options = {
    "layoutControls": {
      miniPlayer: {
        enabled: false
      },
      "controlBar": { "autoHideTimeout": 3, "animated": true, "autoHide": true },
      "htmlOnPauseBlock": { "html": null, "height": "", "width": null }, "autoPlay": true, "mute": false, "allowTheatre": false, "playPauseAnimation": true, "playbackRateEnabled": false, "allowDownload": false, "playButtonShowing": true, "fillToContainer": false, "posterImage": ""
    }, "vastOptions": { "adList": [], "adCTAText": false, "adCTATextPosition": "" },

  }

  fluidPlayer(myVideoPlayer.value, options);


  myVideoPlayer.value.addEventListener('play', () => {
    isPlaying.value = true;
  });

  myVideoPlayer.value.addEventListener('pause', () => {
    isPlaying.value = false;
  });

  // On position change, send time to server (Every 5 seconds to avoid overloading the server)
  myVideoPlayer.value.addEventListener('timeupdate', async () => {
    if (Date.now() - lastDataSent.value > 5000) {
      lastDataSent.value = Date.now();
      if (myVideoPlayer.value.currentTime > 1) { // Don't send data if the video is just starting
        await sendCurrentPosition();
      }
    }
  });

  // Remove muted attribute on load
  myVideoPlayer.value.removeAttribute('muted');
  myVideoPlayer.value.muted = false;
});

const togglePlayPause = () => {
  if (myVideoPlayer.value) {
    if (isPlaying.value) {
      myVideoPlayer.value.pause();
    } else {
      myVideoPlayer.value.play();
    }
    isPlaying.value = !isPlaying.value;
  }
};

const toggleMute = () => {
  if (myVideoPlayer.value) {
    myVideoPlayer.value.muted = !myVideoPlayer.value.muted;
    isMuted.value = myVideoPlayer.value.muted;
  }
};

const sendCurrentPosition = async () => {
  try {
    await axios.put(`/watch/${videoId}/progress.json`, {
      progress: myVideoPlayer.value.currentTime,
      duration: myVideoPlayer.value.duration,
      episodeId: episodeId
    });
    console.log('[Continnum] Current position sent to server (Progress: ' + myVideoPlayer.value.currentTime + ' / ' + myVideoPlayer.value.duration + ')')
  } catch (error) {
    console.error(error);
  }
};

document.addEventListener('contextmenu', (e) => {
  e.preventDefault();
});


</script>

<style scoped>
@import "fluid-player/src/css/fluidplayer.css";

.video-player-container {
  position: relative;
}

.fluid-video {
  width: 100%;
  height: 100%;
}


.custom-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  opacity: 0.9;
  transition: opacity 0.3s ease-in-out;
}

.overlay-content {
  text-align: center;
  color: white;
  padding: 20px;
}

.custom-controls {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-top: 20px;
}

.custom-controls button {
  background-color: transparent;
  border: none;
  color: white;
  font-size: 18px;
  cursor: pointer;
}

.custom-controls button:focus {
  outline: none;
}
</style>
