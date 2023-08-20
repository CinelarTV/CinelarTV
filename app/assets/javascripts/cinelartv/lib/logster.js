/* This handler will report JavaScript errors to
Logster gem, so they are accessible from "/logs" */

import AppRouter from "../routes/router-map";
import { SiteSettings } from "../pre-initializers/essentials-preload";

var lastReport = null;

if (!window.Logster) {
	window.Logster = {
		enabled: SiteSettings.enable_js_error_reporting
	};
}

if(!Logster.enabled) {
    if(process.env.NODE_ENV === 'development') {
        console.warn("DEV: JS error reporting is disabled.\nThis message is only shown in development mode.");
    }
}


export const reportError = (err, severity) => {
    if(!err) return;
    if (severity === 'error') {
        console.error(err)
    } else {
        console.warn(err)
    }

    if (lastReport && new Date() - lastReport < 1000 * 60) {
        return;
    }


    lastReport = new Date();

    let reportData = {
        message: err.name,
        url: AppRouter.currentRoute.value.fullPath,
        window_location: window.location && (window.location + ""),
        stacktrace: err.stack,
        severity,
    }

    if(!SiteSettings.enable_js_error_reporting) {
        return;
    }

    if(process.env.NODE_ENV !== 'development') {
        axios.post("/logs/report_js_error",
            reportData
        );
    }
}



export default {
	install: (app) => {
		app.config.errorHandler = function(err, vm, info) {
			reportError(err, 'error')
		};

		app.config.warnHandler = function(err, vm, info) {
			reportError(err, 'warning')
		};

	}
};