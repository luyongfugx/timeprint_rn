/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */
import React, { useState,useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { Users, Chrome as Home,Settings } from 'lucide-react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
// 引入你创建的页面组件
import HomeScreen from './screens/HomeScreen';
import MembersManagement from './screens/Members';
import ProfileScreen from './screens/ProfileScreen';
import PhotoViewScreen from './screens/PhotoViewScreen';
import { ActivityIndicator, View } from 'react-native';
import { I18nextProvider,useTranslation } from 'react-i18next';
import i18n from './i18n';
import { initI18n } from './i18n';

const Tab = createBottomTabNavigator();
const Stack = createNativeStackNavigator();

function MainTabs() {
  const { t } = useTranslation();
  return (
 
      <Tab.Navigator
        screenOptions={({ route }) => ({
          tabBarIcon: ({ focused, color, size }) => {
            let icon;
            if (route.name === 'Home') {
              icon = focused ? <Home size={size} color={color} /> : <Home size={size} color={color} />;    
            } else if (route.name === 'Member') {
              icon = focused ? <Users size={size} color={color} /> : <Users size={size} color={color} />;
            } else if (route.name === 'Setting') {
              icon = focused ? <Settings size={size} color={color} />  : <Settings size={size} color={color} />;
            }

            // You can return any component that you like here!
            return icon;
          },
          tabBarActiveTintColor: 'tomato', // 选中时的 Tab 颜色
          tabBarInactiveTintColor: 'gray', // 未选中时的 Tab 颜色
          headerShown: false, // 隐藏 Tab 页面自身的头部
        })}
      >
        <Tab.Screen name="Home" component={HomeScreen} options={{ title: t('home') }} />
        <Tab.Screen name="Member" component={MembersManagement} options={{ title: t('member') }} />
        <Tab.Screen name="Setting" component={ProfileScreen} options={{ title: t('me')  }} />
      </Tab.Navigator>

  );
}
function App() {
  const [loading, setLoading] = useState(true);
  // const { initLanguage } = useLanguageStore();

  // useEffect(() => {
  //   initLanguage().finally(() => setLoading(false));
  // }, []);
  // if (loading) {
  //   return (
  //     <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
  //       <ActivityIndicator size="large" />
  //     </View>
  //   );
  // }
  const [ready, setReady] = useState(false);

  useEffect(() => {
    initI18n().then(() => setReady(true));
  }, []);
  if (!ready) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" />
      </View>
    );
  }
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <NavigationContainer>    
        <I18nextProvider i18n={i18n}>
        <Stack.Navigator initialRouteName="Main">
          <Stack.Screen name="PhotoView" component={PhotoViewScreen} options={{ headerShown: false }}/>
          <Stack.Screen name="Main" component={MainTabs} options={{ headerShown: false }} />
        </Stack.Navigator>
        </I18nextProvider>
      </NavigationContainer>
    </GestureHandlerRootView>
  );
}

export default App;
