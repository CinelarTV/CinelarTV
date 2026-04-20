class PerformanceMonitor {
    constructor() {
        this.metrics = {};
        this.startTime = performance.now();
        this.observers = [];
    }

    mark(name) {
        const timestamp = performance.now();
        this.metrics[name] = timestamp;
        console.log(`📊 [Performance] Mark: ${name} at ${timestamp.toFixed(2)}ms`);
        return timestamp;
    }

    measure(name, startMark, endMark) {
        const startTime = this.metrics[startMark];
        const endTime = endMark ? this.metrics[endMark] : performance.now();

        if (!startTime) {
            console.warn(`⚠️ [Performance] Start mark "${startMark}" not found`);
            return null;
        }

        const duration = endTime - startTime;
        this.metrics[name] = duration;
        console.log(`⏱️ [Performance] ${name}: ${duration.toFixed(2)}ms`);
        return duration;
    }

    measureBootTime() {
        this.mark('boot-start');

        // Medir tiempo hasta primer render
        if (typeof window !== 'undefined') {
            window.addEventListener('load', () => {
                this.measure('boot-complete', 'boot-start');
                this.reportMetrics();
            });
        }
    }

    measureComponentLoad(componentName, loadFunction) {
        const startMark = `${componentName}-load-start`;
        this.mark(startMark);

        return loadFunction().then(result => {
            this.measure(`${componentName}-load-time`, startMark);
            return result;
        }).catch(error => {
            this.measure(`${componentName}-load-error`, startMark);
            throw error;
        });
    }

    reportMetrics() {
        const metrics = {
            bootTime: this.metrics['boot-complete'],
            components: {},
            memory: this.getMemoryUsage(),
            timing: this.getNavigationTiming()
        };

        // Extraer métricas de componentes
        Object.keys(this.metrics).forEach(key => {
            if (key.includes('-load-time')) {
                const componentName = key.replace('-load-time', '');
                metrics.components[componentName] = this.metrics[key];
            }
        });

        console.group('📊 Performance Report');
        console.table(metrics.components);
        console.log(`🚀 Total Boot Time: ${metrics.bootTime?.toFixed(2)}ms`);
        console.log(`💾 Memory Usage: ${metrics.memory.usedJSHeapSize?.toFixed(2)}MB`);
        console.groupEnd();

        // Generar resumen textual
        this.generateTextualSummary(metrics);

        // Enviar métricas a analytics si está disponible
        if (window.gtag) {
            window.gtag('event', 'boot_time', {
                custom_parameter: metrics.bootTime
            });
        }

        return metrics;
    }

    generateTextualSummary(metrics) {
        console.log('\n📋 === RESUMEN DE RENDIMIENTO ===');

        // Tiempo total de boot
        const bootTime = metrics.bootTime;
        let bootPerformance = '🟢 Excelente';
        if (bootTime > 3000) bootPerformance = '🔴 Lento';
        else if (bootTime > 2000) bootPerformance = '🟡 Regular';
        else if (bootTime > 1000) bootPerformance = '🟢 Bueno';

        console.log(`⏱️  Tiempo de Boot: ${bootTime?.toFixed(2)}ms ${bootPerformance}`);

        // Análisis de componentes
        console.log('\n🔧 Análisis de Componentes:');
        Object.entries(metrics.components).forEach(([component, time]) => {
            let status = '✅';
            if (time > 500) status = '🔴';
            else if (time > 200) status = '🟡';

            console.log(`   ${status} ${component}: ${time.toFixed(2)}ms`);
        });

        // Uso de memoria
        if (metrics.memory) {
            const memoryMB = metrics.memory.usedJSHeapSize;
            let memoryStatus = '✅ Eficiente';
            if (memoryMB > 100) memoryStatus = '🔴 Alto';
            else if (memoryMB > 50) memoryStatus = '🟡 Moderado';

            console.log(`\n💾 Uso de Memoria: ${memoryMB.toFixed(2)}MB ${memoryStatus}`);
        }

        // Timing de navegación
        if (metrics.timing) {
            console.log('\n🌐 Timing de Navegación:');
            console.log(`   📄 DOM Content Loaded: ${metrics.timing.domContentLoaded.toFixed(2)}ms`);
            console.log(`   🚀 Load Complete: ${metrics.timing.loadComplete.toFixed(2)}ms`);
            console.log(`   🎨 First Paint: ${metrics.timing.firstPaint.toFixed(2)}ms`);
        }

        // Recomendaciones
        console.log('\n💡 Recomendaciones:');
        const recommendations = [];

        if (bootTime > 2000) {
            recommendations.push('Considera más lazy loading para componentes pesados');
        }

        Object.entries(metrics.components).forEach(([component, time]) => {
            if (time > 500) {
                recommendations.push(`${component} está tardando mucho, revisa su implementación`);
            }
        });

        if (metrics.memory && metrics.memory.usedJSHeapSize > 50) {
            recommendations.push('El uso de memoria es elevado, considera liberar recursos');
        }

        if (recommendations.length === 0) {
            console.log('   ✅ El rendimiento es óptimo');
        } else {
            recommendations.forEach(rec => console.log(`   • ${rec}`));
        }

        console.log('=====================================\n');
    }

    getMemoryUsage() {
        if (performance.memory) {
            return {
                usedJSHeapSize: performance.memory.usedJSHeapSize / 1024 / 1024,
                totalJSHeapSize: performance.memory.totalJSHeapSize / 1024 / 1024,
                jsHeapSizeLimit: performance.memory.jsHeapSizeLimit / 1024 / 1024
            };
        }
        return null;
    }

    getNavigationTiming() {
        if (performance.timing) {
            const timing = performance.timing;
            return {
                domContentLoaded: timing.domContentLoadedEventEnd - timing.navigationStart,
                loadComplete: timing.loadEventEnd - timing.navigationStart,
                firstPaint: timing.responseStart - timing.navigationStart
            };
        }
        return null;
    }

    // Observer para medir Long Tasks
    observeLongTasks() {
        if ('PerformanceObserver' in window) {
            let lastWarningTime = 0;
            const WARNING_COOLDOWN = 5000; // 5 segundos entre warnings

            const observer = new PerformanceObserver((list) => {
                const now = performance.now();

                list.getEntries().forEach((entry) => {
                    // Solo alertar sobre tareas realmente largas (> 100ms)
                    if (entry.duration > 100) {
                        // Limitar frecuencia de warnings para evitar spam
                        if (now - lastWarningTime > WARNING_COOLDOWN) {
                            console.warn(`🐌 Long Task detected: ${entry.duration.toFixed(2)}ms`, {
                                duration: entry.duration,
                                startTime: entry.startTime,
                                attribution: entry.attribution
                            });
                            lastWarningTime = now;
                        }
                    }
                });
            });

            observer.observe({ entryTypes: ['longtask'] });
            this.observers.push(observer);
        }
    }

    // Observer para medir Resource Timing
    observeResources() {
        if ('PerformanceObserver' in window) {
            const observer = new PerformanceObserver((list) => {
                const resources = list.getEntries();

                // Filtrar recursos que no deben considerarse "lentos"
                const filteredResources = resources.filter(r => {
                    // Excluir llamadas a API (generalmente rápidas y necesarias)
                    if (r.name.includes('/api/') || r.name.includes('/admin/')) {
                        return false;
                    }

                    // Excluir recursos de analytics y tracking
                    if (r.name.includes('analytics') || r.name.includes('gtag') || r.name.includes('gtm')) {
                        return false;
                    }

                    // Excluir websockets y conexiones en tiempo real
                    if (r.name.includes('ws://') || r.name.includes('wss://') || r.name.includes('cable')) {
                        return false;
                    }

                    // Excluir favicons y recursos muy pequeños
                    if (r.name.includes('favicon') || r.transferSize < 1024) {
                        return false;
                    }

                    return true;
                });

                const slowResources = filteredResources.filter(r => r.duration > 100);

                if (slowResources.length > 0) {
                    console.warn('🐌 Slow resources detected:', slowResources.map(r => ({
                        name: r.name.split('/').pop(),
                        duration: `${r.duration.toFixed(2)}ms`,
                        size: r.transferSize ? `${(r.transferSize / 1024).toFixed(1)}KB` : 'N/A'
                    })));
                }
            });

            observer.observe({ entryTypes: ['resource'] });
            this.observers.push(observer);
        }
    }

    start() {
        this.measureBootTime();
        this.observeLongTasks();
        this.observeResources();
        console.log('📊 Performance monitoring started');
    }

    destroy() {
        this.observers.forEach(observer => observer.disconnect());
        this.observers = [];
    }
}

// Singleton instance
const performanceMonitor = new PerformanceMonitor();

export default performanceMonitor;
