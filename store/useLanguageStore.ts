import { create } from 'zustand';
// import AsyncStorage from '@react-native-async-storage/async-storage';
// import i18n from '../i18n';

// export type Language = 'en' | 'zh';

// interface LanguageState {
//   language: Language;
//   setLanguage: (lang: Language) => Promise<void>;
//   initLanguage: () => Promise<void>;
// }

// const LANG_KEY = 'user-language';

// export const useLanguageStore = create<LanguageState>((set) => ({
//   language: 'en',

//   setLanguage: async (lang: Language) => {
//     await i18n.changeLanguage(lang);
//     await AsyncStorage.setItem(LANG_KEY, lang);
//     set({ language: lang });
//   },

//   initLanguage: async () => {
//     const saved = (await AsyncStorage.getItem(LANG_KEY)) as Language | null;
//     const fallback = 'en';
//     const lang = saved || fallback;
//     await i18n.changeLanguage(lang);
//     set({ language: lang });
//   },
// }));
