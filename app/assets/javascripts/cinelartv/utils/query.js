// Función para obtener todos los parámetros de consulta de una URL y retornarlos como objeto JSON
const getQueryParams = (url) => {
    const queryParams = {};
    const urlSearchParams = new URLSearchParams(url.search);

    for (const [key, value] of urlSearchParams.entries()) {
        queryParams[key] = value;
    }

    return queryParams;
}

// Obtener todos los parámetros de consulta de la URL actual y almacenarlos en QUERY_PARAMS
export const query = getQueryParams(window.location);
