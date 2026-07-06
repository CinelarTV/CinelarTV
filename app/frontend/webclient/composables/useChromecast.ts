import { shallowRef, onBeforeUnmount } from 'vue';

export function useChromecast() {
    const isCasting = shallowRef(false);
    const isAvailable = shallowRef(false);

    let castProxy: any = null;
    let eventManager: any = null;

    function loadCastSdk(): Promise<void> {
        return new Promise((resolve, reject) => {
            if (window.chrome?.cast) {
                resolve();
                return;
            }
            // Check if script already exists
            const existing = document.querySelector('script[src="https://www.gstatic.com/cv/js/sender/v1/cast_sender.js"]');
            if (existing) {
                // Wait for it to load
                const check = setInterval(() => {
                    if (window.chrome?.cast) {
                        clearInterval(check);
                        resolve();
                    }
                }, 100);
                setTimeout(() => { clearInterval(check); reject(new Error('Cast SDK load timeout')); }, 5000);
                return;
            }
            const script = document.createElement('script');
            script.src = 'https://www.gstatic.com/cv/js/sender/v1/cast_sender.js';
            script.onload = () => {
                // Wait for chrome.cast to be available
                const check = setInterval(() => {
                    if (window.chrome?.cast) {
                        clearInterval(check);
                        resolve();
                    }
                }, 100);
                setTimeout(() => { clearInterval(check); reject(new Error('Cast SDK init timeout')); }, 5000);
            };
            script.onerror = () => reject(new Error('Failed to load Cast SDK'));
            document.head.appendChild(script);
        });
    }

    async function init(player: any, video: HTMLVideoElement) {
        try {
            await loadCastSdk();

            const shaka = await import('shaka-player');
            const CastProxyClass = (shaka as any).cast?.CastProxy;

            if (!CastProxyClass) {
                console.warn('Shaka CastProxy not available');
                return;
            }

            castProxy = new CastProxyClass(player, video, '');

            eventManager = new shaka.util.EventManager();

            eventManager.listen(castProxy, 'caststatuschanged', () => {
                isCasting.value = castProxy.isCasting();
            });

            isAvailable.value = castProxy.canCast();
        } catch (error) {
            // Chromecast not available — this is normal on most devices
            isAvailable.value = false;
        }
    }

    async function startCast() {
        if (!castProxy) return;
        try {
            await castProxy.cast();
            isCasting.value = true;
        } catch (error) {
            console.warn('Failed to start casting:', error);
        }
    }

    async function stopCast() {
        if (!castProxy) return;
        try {
            await castProxy.suspend();
            isCasting.value = false;
        } catch (error) {
            console.warn('Failed to stop casting:', error);
        }
    }

    function toggleCast() {
        if (isCasting.value) {
            stopCast();
        } else {
            startCast();
        }
    }

    onBeforeUnmount(() => {
        eventManager?.removeAll();
        castProxy = null;
    });

    return {
        isCasting,
        isAvailable,
        init,
        startCast,
        stopCast,
        toggleCast,
    };
}
