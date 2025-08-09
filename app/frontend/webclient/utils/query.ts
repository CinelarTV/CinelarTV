// Devuelve los parámetros de consulta de la URL actual como objeto
export const query = Object.fromEntries(new URLSearchParams(window.location.search));
