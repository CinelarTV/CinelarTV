import {reportError} from './logster.js';

export default function deprecated(msg, options = {}) {
    const { deprecatedFunction, since, dropFrom } = options;
    msg = ["Deprecation notice:", msg];

    if (since) {
        msg.push([`(deprecated since CinelarTV ${since}`]);
    }

    if (!dropFrom && since) {
        msg.push([`)`]);
    }
    if (dropFrom) {

        if (since) {
            msg.push([`, removal from CinelarTV ${dropFrom})`]);
        }
        else {

            msg.push([`removal from CinelarTV ${dropFrom}`]);

        }
    }

    msg = msg.join(' ');

    reportError(new Error(msg), 'warning');
 }
