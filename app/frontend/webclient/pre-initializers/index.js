// Carga todos los archivos JS en el directorio excepto index.js usando import.meta.glob
console.log('Loading pre-initializers...');
const modules = import.meta.glob('./!(index).js', { eager: true });

const preInitializers = Object.values(modules).map(m => {
    try {
        return m.default;
    } catch (error) {
        console.error(`Error loading pre-initializer: ${error}`);
        return null;
    }
});

export default preInitializers;
