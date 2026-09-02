import { defineComponent } from 'vue';
import CStatCard from '@/components/CStatCard';

export default defineComponent({
    name: 'StatsSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Stats Cards</h1>
                <p class="styleguide-section__description">
                    Componente <code>c-stat-card</code> para metricas y estadisticas en dashboards.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">With Trend</h2>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '16px' }}>
                        <CStatCard label="Total Users" value="12,847" icon="users" trend="up" trendValue="+12%" trendLabel="vs last month" />
                        <CStatCard label="Active Sessions" value="3,291" icon="activity" trend="up" trendValue="+5%" trendLabel="vs last month" />
                        <CStatCard label="Revenue" value="$48,352" icon="dollar-sign" trend="down" trendValue="-2%" trendLabel="vs last month" />
                        <CStatCard label="Conversion" value="3.24%" icon="trending-up" trend="up" trendValue="+0.8%" trendLabel="vs last month" />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Accent Variant</h2>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '16px' }}>
                        <CStatCard label="Movies" value="2,451" icon="film" variant="accent" color="primary" />
                        <CStatCard label="Series" value="892" icon="tv" variant="accent" color="info" />
                        <CStatCard label="Users Online" value="1,204" icon="users" variant="accent" color="success" />
                        <CStatCard label="Storage Used" value="2.4 TB" icon="hard-drive" variant="accent" color="warning" />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Compact Inline</h2>
                    <div class="styleguide-row" style={{ gap: '24px' }}>
                        <CStatCard label="Uptime" value="98.5%" />
                        <CStatCard label="Avg Response" value="142ms" />
                        <CStatCard label="Cache Size" value="4.2GB" />
                    </div>
                </div>
            </div>
        );
    }
});
