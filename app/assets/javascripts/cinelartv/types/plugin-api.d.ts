declare interface Banner {
    id: string;
    content: string;
    show: boolean;
    customHtml: string;
    css: string;
    dismissable: boolean;
    dismiss_text: string;
    dismiss_callback: Function;
    icon: string;
  }

  declare interface PluginAPI {
    version: string;
    currentInstance(): any;
    addGlobalNotice(notice: Banner): void;
    removeGlobalNotice(id: string): void;
    getCurrentUser(): any;
    getSiteSettings(): any;
    ref(value: any): any;
    replaceIcon(iconName: string, svgIcon: string): void;
    addIcon(iconName: string, svgIcon?: string | null): void;
    getCustomData(): any;
    loadScript(url: string): Promise<void>;
  }