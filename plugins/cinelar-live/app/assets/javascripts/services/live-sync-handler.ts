const DRIFT_THRESHOLD = 3;
const DRIFT_HARD_THRESHOLD = 10;

export interface LiveSyncData {
  current_time: number;
  is_playing: boolean;
  source?: string;
}

export function createLiveSyncHandler(videoEl: HTMLVideoElement) {
  let lastReceivedPosition = 0;

  const handleSync = (data: LiveSyncData) => {
    lastReceivedPosition = data.current_time;
    const drift = Math.abs(videoEl.currentTime - data.current_time);

    if (drift <= DRIFT_THRESHOLD) return;

    if (drift <= DRIFT_HARD_THRESHOLD) {
      const speed = videoEl.playbackRate;
      if (videoEl.currentTime < data.current_time) {
        videoEl.playbackRate = 1.05;
      } else {
        videoEl.playbackRate = 0.95;
      }
      setTimeout(() => { videoEl.playbackRate = speed; }, 2000);
    } else {
      videoEl.currentTime = data.current_time;
    }
  };

  const getLiveEdge = () => lastReceivedPosition;

  const seekToLive = () => {
    videoEl.currentTime = lastReceivedPosition;
  };

  const applyInitialState = (data: { current_time: number; is_playing: boolean }) => {
    videoEl.currentTime = data.current_time;
    lastReceivedPosition = data.current_time;
    if (data.is_playing) {
      videoEl.play().catch(() => {});
    }
  };

  return { handleSync, getLiveEdge, seekToLive, applyInitialState };
}
