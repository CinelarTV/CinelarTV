const loadScript = (src, inlineCode = null) => {
    return new Promise((resolve, reject) => {
        if (src) {
            const script = document.createElement('script');
            script.src = src;
            script.async = true;
            script.onload = resolve;
            script.onerror = reject;
            document.head.appendChild(script);
        } else if (inlineCode) {
            try {
                const script = document.createElement('script');
                script.text = inlineCode;
                document.head.appendChild(script);
                resolve();
            } catch (error) {
                reject(error);
            }
        } else {
            reject(new Error('Neither src nor inlineCode provided.'));
        }
    });
}

export default loadScript;