import { useEffect } from "react";
import { create } from "zustand";
import { useI18n } from '../services/i18n';

// Store zustand para el estado de red
interface NetworkState {
    isOnline: boolean;
    setIsOnline: (online: boolean) => void;
}

export const useNetworkStore = create<NetworkState>((set) => ({
    isOnline: typeof navigator !== 'undefined' ? navigator.onLine : true,
    setIsOnline: (online) => set({ isOnline: online }),
}));

export const useNetworkListener = () => {
    const setIsOnline = useNetworkStore((s) => s.setIsOnline);
    useEffect(() => {
        const handleOnline = () => {
            setIsOnline(true);
            document.body.classList.remove('cinelar-offline');
        };
        const handleOffline = () => {
            setIsOnline(false);
            document.body.classList.add('cinelar-offline');
        };
        window.addEventListener('online', handleOnline);
        window.addEventListener('offline', handleOffline);
        return () => {
            window.removeEventListener('online', handleOnline);
            window.removeEventListener('offline', handleOffline);
        };
    }, [setIsOnline]);
};

export const OfflineIndicator: React.FC = () => {
    const isOnline = useNetworkStore((s) => s.isOnline);
    useNetworkListener();
    const t = useI18n();

    if (isOnline) return null;

    return (
        <div className="offline-indicator">
            <span>{t('js.offline_indicator.no_internet')}</span>
            <div className="flex justify-center mt-2">
                <button
                    onClick={() => window.location.reload()}
                    className="bg-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline hover:bg-gray-100 hover:text-gray-900 mt-4"
                >
                    {t('js.offline_indicator.reload')}
                </button>
            </div>
        </div>
    );
};
