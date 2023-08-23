import axios from 'axios';
import CinelarTV from '../application';
let csrf = document.querySelector('meta[name="csrf-token"]').getAttribute('content');


const http = axios.create({
    timeout: 30000,
    headers: {
        common: {
            "X-CSRF-TOKEN": csrf
        }
    }
  });

  http.interceptors.request.use(function (config) {
    CinelarTV.config.globalProperties.$progress.start()
    return config;
  }, function (error) {
    CinelarTV.config.globalProperties.$progress.finish()
    return Promise.reject(error);
  });

  http.interceptors.response.use(function (response) {
    CinelarTV.config.globalProperties.$progress.finish()
    if(response.status === 200 || response.status === 422) {
      return response;  
    }
  }, function (error) {
    if (error.response.status === 404) {
        //AppRouter.replace('/not-found')
    }

    if (error.response.status === 500 || error.response.code === 502) {
        if (process.env.NODE_ENV !== 'development') {
          //AppRouter.replace('/exception')
        }
    }
    if(error.response.status === 422) {
      return Promise.reject(error.response.data);
    }
    return Promise.reject(error);
  });


window.axios = http

export default {
    install: (app) => {
        app.config.globalProperties.$http = http
    }
}