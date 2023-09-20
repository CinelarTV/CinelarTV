import axios from 'axios';
import CinelarTV from '../application';

const getCsrfToken = () => {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content');
}

export const ajax = axios.create({
    timeout: 30000,
    headers: {
        common: {
            "X-CSRF-TOKEN": getCsrfToken()
        }
    }
});

ajax.interceptors.request.use(function (config) {
    CinelarTV.config.globalProperties.$progress.start();
    document.body.classList.add('ajax-loading');
    return config;
}, function (error) {
    CinelarTV.config.globalProperties.$progress.finish();
    document.body.classList.remove('ajax-loading');
    return Promise.reject(error);
});

ajax.interceptors.response.use(function (response) {
    CinelarTV.config.globalProperties.$progress.finish();
    document.body.classList.remove('ajax-loading');
    if (response.status === 200 || response.status === 422) {
        return response;
    }
}, function (error) {
    CinelarTV.config.globalProperties.$progress.finish();
    document.body.classList.remove('ajax-loading');
    if (error.response.status === 404) {
        // AppRouter.replace('/not-found');
    }

    if (error.response.status === 500 || error.response.code === 502) {
        if (process.env.NODE_ENV !== 'development') {
            // AppRouter.replace('/exception');
        }
    }

    if (error.response.status === 422) {
        document.body.classList.remove('ajax-loading');
        return Promise.reject(error.response.data);
    }

    return Promise.reject(error);
});

// Función para renovar el token CSRF periódicamente
const renewCsrfToken = () => {
  const interval = setInterval(async () => {
      try {
          const response = await axios.get('/session/csrf');
          const newCsrfToken = response.data.csrf;
          ajax.defaults.headers.common["X-CSRF-TOKEN"] = newCsrfToken;
      } catch (error) {
          console.error("[Ajax] Error on renewing CSRF token", error);
      }
  }, 60 * 60 * 1000); 
}

renewCsrfToken();

window.ajax = ajax;

export default {
    install: (app) => {
        app.config.globalProperties.$http = ajax;
    }
};
