import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import en from './locales/en.json';
import zh from './locales/zh.json';

const LANG_KEY = 'user-language';

const resources = {
  en: { translation: en },
  zh: { translation: zh },
};

const fallbackLng = 'en';
const detectLanguage = () => {
  const lang = Intl?.DateTimeFormat?.()?.resolvedOptions()?.locale;
  return lang?.split('-')[0] || 'en';
};
export const initI18n = async () => {
  const lng =  detectLanguage();
  return i18n
    .use(initReactI18next)
    .init({
      
    //   compatibilityJSON: 'v3',
      resources,
      lng,
      fallbackLng,
      interpolation: { escapeValue: false },
    });
};
export default i18n;
