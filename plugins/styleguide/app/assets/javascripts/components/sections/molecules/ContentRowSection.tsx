import { defineComponent } from 'vue';
import ContentRow from '@/components/content-row.vue';

const mockRow1 = [
    { id: 1, title: 'The Matrix', banner: 'https://image.tmdb.org/t/p/w500/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg', isPrime: false, progress: 0, duration: 8160, year: 1999, rating: '8.7', genres: ['Sci-Fi', 'Action'] },
    { id: 2, title: 'Inception', banner: 'https://image.tmdb.org/t/p/w500/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', isPrime: false, progress: 2400, duration: 8880, year: 2010, rating: '8.4', genres: ['Sci-Fi', 'Thriller'] },
    { id: 3, title: 'Interstellar', banner: 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', isPrime: false, progress: 10000, duration: 9960, year: 2014, rating: '8.6', genres: ['Sci-Fi', 'Drama'] },
    { id: 4, title: 'The Dark Knight', banner: 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911BTUgMe1nF1iC.jpg', isPrime: false, progress: 0, duration: 9120, year: 2008, rating: '9.0', genres: ['Action', 'Crime'] },
    { id: 5, title: 'Pulp Fiction', banner: 'https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg', isPrime: false, progress: 8000, duration: 9240, year: 1994, rating: '8.9', genres: ['Crime', 'Drama'] },
    { id: 6, title: 'Forrest Gump', banner: 'https://image.tmdb.org/t/p/w500/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg', isPrime: false, progress: 0, duration: 8520, year: 1994, rating: '8.8', genres: ['Drama', 'Romance'] },
    { id: 7, title: 'Gladiator', banner: 'https://image.tmdb.org/t/p/w500/ty8TGRuvJLPUmAR1H1nRIsgCLYV.jpg', isPrime: false, progress: 3000, duration: 9300, year: 2000, rating: '8.5', genres: ['Action', 'Drama'] },
    { id: 8, title: 'The Godfather', banner: 'https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg', isPrime: false, progress: 0, duration: 10500, year: 1972, rating: '9.2', genres: ['Crime', 'Drama'] }
];

const mockRow2 = [
    { id: 9, title: 'Breaking Bad', banner: 'https://image.tmdb.org/t/p/w500/ggFHVNu6YYI5L9pCfOacjizRGt.jpg', isPrime: false, progress: 20000, duration: 45000, year: 2008, rating: '9.5', genres: ['Crime', 'Drama'], isNew: false },
    { id: 10, title: 'Game of Thrones', banner: 'https://image.tmdb.org/t/p/w500/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg', isPrime: false, progress: 73000, duration: 73000, year: 2011, rating: '9.3', genres: ['Fantasy', 'Drama'], isNew: false },
    { id: 11, title: 'Stranger Things', banner: 'https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn8AIqMGskD.jpg', isPrime: false, progress: 3000, duration: 25000, year: 2016, rating: '8.7', genres: ['Sci-Fi', 'Horror'], isNew: true },
    { id: 12, title: 'The Witcher', banner: 'https://image.tmdb.org/t/p/w500/7vjaCdMw15FEbXyLQTVa04URsPm.jpg', isPrime: false, progress: 0, duration: 60000, year: 2019, rating: '8.2', genres: ['Fantasy', 'Action'], isNew: false }
];

export default defineComponent({
    name: 'ContentRowSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">ContentRow</h1>
                <p class="styleguide-section__description">
                    Fila horizontal desplazable de tarjetas de contenido.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Trending Now</h2>
                    <ContentRow title="Trending Now" items={mockRow1} />
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Continue Watching</h2>
                    <ContentRow title="Continue Watching" items={mockRow2} />
                </div>
            </div>
        );
    }
});
