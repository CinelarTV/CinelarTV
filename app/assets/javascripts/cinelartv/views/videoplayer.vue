<template>
    <div class="video-player-container">
      <video-player :src="videoSrc" poster="/your-path/poster.jpg" :loop="true" :volume="0.6" :fluid="true">
        <template v-slot="{ player, state }">
          <div class="custom-player-overlay" v-if="state.playing || state.paused"> <!-- Update condition here -->
            <!-- Netflix-style overlay content -->
            <div class="overlay-content">
              <h2>{{ videoTitle }}</h2>
              <p>{{ videoDescription }}</p>
            </div>
  
            <!-- Custom player controls -->
            <div class="custom-player-controls">
              <button @click="state.playing ? player.pause() : player.play()">
                {{ state.playing ? 'Pause' : 'Play' }}
              </button>
              <button @click="player.muted(!state.muted)">
                {{ state.muted ? 'UnMute' : 'Mute' }}
              </button>
              <!-- more custom controls elements ... -->
            </div>
          </div>
        </template>
      </video-player>
    </div>
  </template>
  
  <script setup>
  import { onMounted } from 'vue';
  import { VideoPlayer } from '@videojs-player/vue';
  import 'video.js/dist/video-js.css';
  
  const videoSrc = 'https://video-r2.nickelodeonplus.online/20230427230610_10x207/20230427230610_10x207.m3u8';
  const videoTitle = 'Video Title';
  const videoDescription = 'Video Description';
  
  </script>
  
  
  <style scoped>
  .video-player-container {
    position: relative;
  }
  
  .custom-player-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.7);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 2;
    transition: opacity 0.3s ease-in-out;
    opacity: 1;
  }
  
  .overlay-content {
    text-align: center;
    color: white;
    padding: 20px;
  }
  
  .custom-player-controls {
    display: flex;
    justify-content: center;
    margin-top: 20px;
  }
  
  .custom-player-controls button {
    background-color: transparent;
    border: none;
    cursor: pointer;
    padding: 10px 20px;
    font-size: 16px;
    color: white;
  }
  
  </style>
  