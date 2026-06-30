import { defineComponent } from 'vue';
import ContentCard from '@/components/content-card.vue';

const mockContent = [
    {
        id: 1,
        title: 'The Matrix',
        description: 'A computer hacker learns about the true nature of reality.',
        banner: 'https://image.tmdb.org/t/p/w500/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
        premium: false,
        progress: 0
    },
    {
        id: 2,
        title: 'Inception',
        description: 'A thief who steals corporate secrets through dream-sharing technology.',
        banner: 'https://image.tmdb.org/t/p/w500/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg',
        premium: false,
        progress: 2400
    },
    {
        id: 3,
        title: 'Interstellar',
        description: 'A team of explorers travel through a wormhole in space.',
        banner: 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        premium: false,
        progress: 10000
    },
    {
        id: 4,
        title: 'Without Image',
        description: 'This card has no banner image.',
        banner: null,
        premium: false,
        progress: 0
    }
];

export default defineComponent({
    name: 'ContentCardSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">ContentCard</h1>
                <p class="styleguide-section__description">
                    Tarjeta de contenido con imagen, título, descripción y barra de progreso.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Variants</h2>
                    <div class="styleguide-content-grid">
                        {mockContent.map(item => (
                            <div class="styleguide-content-grid__item" key={item.id}>
                                <ContentCard data={item} />
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        );
    }
});
