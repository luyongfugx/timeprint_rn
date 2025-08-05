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

// const detectLanguage = async () => {
//   // const storedLang = await AsyncStorage.getItem(LANG_KEY);
//   // if (storedLang) return storedLang;
//   //RNLocalize.findBestLanguageTag
//   const best = findBestLanguageTag(Object.keys(resources));
//   const systemLang = Platform.OS === 'ios' || Platform.OS === 'android'
//   ? (Intl.DateTimeFormat().resolvedOptions().locale || 'en')
//   : 'en';

//   return best?.languageTag || fallbackLng;
// };

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

// export const changeLanguage = async (lang: 'en' | 'zh') => {
//   await i18n.changeLanguage(lang);
//   await AsyncStorage.setItem(LANG_KEY, lang);
// };

export default i18n;
