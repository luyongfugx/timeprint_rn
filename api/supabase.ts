// src/services/supabase.ts (或任意您喜欢的路径)
import 'react-native-url-polyfill/auto';
import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '../__mocks__/@react-native-async-storage/async-storage/index';

const SUPABASE_URL = 'https://jagoxfrvvxfnpdjvbtrf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphZ294ZnJ2dnhmbnBkanZidHJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU5MzM5NDUsImV4cCI6MjA3MTUwOTk0NX0.P1wI24InDGhCHYltNSWUXQshp-OcM38WUGGCg02Pa3Q';

// 创建 Supabase 客户端实例
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});