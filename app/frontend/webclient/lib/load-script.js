const getNonce = () => document.querySelector('meta[name="csp-nonce"]')?.content;

const loadScript = (src, inlineCode = null) => {
    return new Promise((resolve, reject) => {
        if (src) {
            const script = document.createElement('script');
            script.src = src;
            script.async = true;
            const nonce = getNonce();
            if (nonce) script.setAttribute('nonce', nonce);
            script.onload = () => {
                console.log('[Script] External script loaded: ' + src);
                resolve();
            };
            script.onerror = (error) => {
                const err = new Error('Failed to load script: ' + src);
                console.error('[Script Error]', err);
                reject(err);
            };
            document.head.appendChild(script);
        } else if (inlineCode) {
            try {
                const script = document.createElement('script');
                script.text = inlineCode;
                script.type = 'text/javascript';
                const nonce = getNonce();
                if (nonce) script.setAttribute('nonce', nonce);
                document.head.appendChild(script);
                console.log('[Script] Inline script executed');
                resolve();
            } catch (error) {
                console.error('[Script Error] Error executing inline script:', error);
                reject(error);
            }
        } else {
            const err = new Error('Neither src nor inlineCode provided.');
            console.error('[Script Error]', err);
            reject(err);
        }
    });
}

export default loadScript;