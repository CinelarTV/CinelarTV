import { reportError } from './Logster';

interface DeprecatedOptions {
    deprecatedFunction?: string;
    since?: string;
    dropFrom?: string;
}

export default function deprecated(msg: string, options: DeprecatedOptions = {}): void {
    const { deprecatedFunction, since, dropFrom } = options;
    let parts: string[] = ["Deprecation notice:", msg];

    if (since) {
        parts.push(`(deprecated since CinelarTV ${since}`);
    }

    if (!dropFrom && since) {
        parts.push(")");
    }
    if (dropFrom) {
        if (since) {
            parts.push(`, removal from CinelarTV ${dropFrom})`);
        } else {
            parts.push(`removal from CinelarTV ${dropFrom}`);
        }
    }

    const fullMsg = parts.join(' ');
    console.log("called deprecated")
    reportError(new Error(fullMsg), 'warning');
}
