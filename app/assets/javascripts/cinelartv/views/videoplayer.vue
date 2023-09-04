<template>
  <div class="video-player-container">
    <video ref="myVideoPlayer" class="fluid-video" controls>
      <source src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4" type="video/mp4" />
    </video>

  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import fluidPlayer from 'fluid-player';

const myVideoPlayer = ref(null);
const showOverlay = ref(true);
const isPlaying = ref(false);
const isMuted = ref(false);
const videoTitle = 'Video Title';
const videoDescription = 'Video Description';

onMounted(() => {
  document.body.classList.add('video-player');
  const options = {
    "layoutControls": {
      "controlBar": { "autoHideTimeout": 3, "animated": true, "autoHide": true },
      "title": 'www.nickelodeonplus.online',
      "htmlOnPauseBlock": { "html": null, "height": "", "width": null }, "autoPlay": false, "mute": false, "allowTheatre": false, "playPauseAnimation": true, "playbackRateEnabled": false, "allowDownload": false, "playButtonShowing": true, "fillToContainer": false, "posterImage": ""
    }, "vastOptions": { "adList": [], "adCTAText": false, "adCTATextPosition": "" }
  }

  fluidPlayer(myVideoPlayer.value, options);

  myVideoPlayer.value.addEventListener('play', () => {
    isPlaying.value = true;
  });

  myVideoPlayer.value.addEventListener('pause', () => {
    isPlaying.value = false;
  });
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

.video-player-container {
  height: 100%;
}</style>
