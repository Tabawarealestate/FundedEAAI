export type SupportedLanguage = 'en' | 'fr' | 'es' | 'ar';

export const i18n = {
  en: {
    welcome: (username: string, accessLabel: string) =>
      `Welcome ${username} 👋\n\nYou are connected to Hikima X10 AI.\n\n🟢 AI SCAN ENGINE: ACTIVE\n📡 Monitored Markets: 22 Assets\n⚡ Real-time Multi-Strategy Signals\n🛡 Automatic Signal Monitoring\n\nAccess: ${accessLabel}\n\nUse the bottom menu buttons below to navigate instantly!`,
    signals: '📊 Signals',
    markets: '📈 Markets',
    strategies: '🧠 Strategies',
    premium: '💎 Premium',
    scan_status: '⚡ Scan Status',
    performance: '📊 Performance',
    settings: '⚙️ Settings',
    help: '❓ Help',
    language_updated: '🌐 Language updated to English.',
  },
  fr: {
    welcome: (username: string, accessLabel: string) =>
      `Bienvenue ${username} 👋\n\nVous êtes connecté à Hikima X10 AI.\n\n🟢 MOTEUR DE SCAN AI : ACTIF\n📡 Marchés surveillés : 22 actifs\n⚡ Signaux multi-stratégies en temps réel\n🛡 Surveillance automatique des signaux\n\nAccès : ${accessLabel}\n\nUtilisez le menu ci-dessous pour naviguer instantanément !`,
    signals: '📊 Signaux',
    markets: '📈 Marchés',
    strategies: '🧠 Stratégies',
    premium: '💎 Premium',
    scan_status: '⚡ État du Scan',
    performance: '📊 Performance',
    settings: '⚙️ Paramètres',
    help: '❓ Aide',
    language_updated: '🌐 Langue changée en Français.',
  },
  es: {
    welcome: (username: string, accessLabel: string) =>
      `¡Bienvenido ${username} 👋\n\nEstás conectado a Hikima X10 AI.\n\n🟢 MOTOR DE ESCANEO IA: ACTIVO\n📡 Mercados Monitoreados: 22 Activos\n⚡ Señales Multiestrategia en Tiempo Real\n🛡 Monitoreo Automático de Señales\n\nAcceso: ${accessLabel}\n\n¡Usa los botones del menú a continuación para navegar al instante!`,
    signals: '📊 Señales',
    markets: '📈 Mercados',
    strategies: '🧠 Estrategias',
    premium: '💎 Premium',
    scan_status: '⚡ Estado del Escaneo',
    performance: '📊 Rendimiento',
    settings: '⚙️ Configuración',
    help: '❓ Ayuda',
    language_updated: '🌐 Idioma cambiado a Español.',
  },
  ar: {
    welcome: (username: string, accessLabel: string) =>
      `مرحباً بك ${username} 👋\n\nأنت الآن متصل بـ Hikima X10 AI.\n\n🟢 محرك المسح بالذكاء الاصطناعي: نشط\n📡 الأسواق المراقبة: 22 أصلاً\n⚡ إشارات متعددة الاستراتيجيات في الوقت الفعلي\n🛡 مراقبة تلقائية للإشارات\n\nنوع الاشتراك: ${accessLabel}\n\nاستخدم القائمة في الأسفل للتنقل الفوري!`,
    signals: '📊 الإشارات',
    markets: '📈 الأسواق',
    strategies: '🧠 الاستراتيجيات',
    premium: '💎 الباقة المميزة',
    scan_status: '⚡ حالة المسح',
    performance: '📊 الأداء',
    settings: '⚙️ الإعدادات',
    help: '❓ المساعدة',
    language_updated: '🌐 تم تغيير اللغة إلى العربية بنجاح.',
  },
};

export function getText(lang: string = 'en', key: keyof typeof i18n['en'], ...args: any[]): any {
  const selectedLang = (['en', 'fr', 'es', 'ar'].includes(lang) ? lang : 'en') as SupportedLanguage;
  const val = i18n[selectedLang][key] || i18n['en'][key];
  if (typeof val === 'function') {
    return (val as Function)(...args);
  }
  return val;
}
