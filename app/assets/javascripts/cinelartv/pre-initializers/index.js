const preInitializerContext = require.context('.', false, /^\.\/(?!index\.js$).*\.js$/);

const preInitializers = preInitializerContext.keys()
    .map(preInitializerContext)
    .map(m => {
        try {
            return m.default
        } catch (error) {
            console.error(`Error loading pre-initializer ${m.name}: ${error}`)
            return null
        }
    });

export default preInitializers;
