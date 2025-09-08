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
import { GestureDetector, GestureHandlerRootView,Gesture } from 'react-native-gesture-handler';

// 引入你创建的页面组件
import HomeScreen from './screens/HomeScreen';
import MembersManagement from './screens/Members';
import ProfileScreen from './screens/ProfileScreen';
import PhotoViewScreen from './screens/PhotoViewScreen';
import { ActivityIndicator, View,TouchableOpacity, Platform, StyleSheet,Text,Alert  } from 'react-native';
import { I18nextProvider,useTranslation } from 'react-i18next';
import i18n from './i18n';
import { initI18n } from './i18n';
import { supabase } from './api/supabase';
// import { Text } from 'react-native-svg';
import { GoogleSignin, statusCodes } from '@react-native-google-signin/google-signin';
import Animated, { 
  useAnimatedStyle, 
  withSpring, 
  withTiming,
  useSharedValue,
  interpolate,
  runOnJS,
  FadeInUp,
  FadeInDown
} from 'react-native-reanimated';

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
  const [user, setUser] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [ready, setReady] = useState(false);
  const [agreedToTerms, setAgreedToTerms] = useState(false);

  const buttonScale = useSharedValue(1);
  const checkboxScale = useSharedValue(1);
  const fadeIn = useSharedValue(0);

  useEffect(() => {
    // 检查当前登录状态
    const checkAuthState = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      console.log("session",session)
      setIsLoggedIn(!!session);
      setUser(session?.user || null);
      setIsLoading(false)
    };
    checkAuthState();
    // 监听认证状态变化
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setIsLoggedIn(!!session);
        setUser(session?.user || null);
        setIsLoading(false)
      }
    );
    initI18n().then(() => setReady(true));
    return () => subscription.unsubscribe();

  }, []);
    const handleLogin = async (provider: string) => {
      GoogleSignin.configure({
        scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        webClientId: '401431549807-5jq8d5vicunav6osh0lcof33i260nb64.apps.googleusercontent.com',
      })
      if (!agreedToTerms) {
        Alert.alert('提示', '请先阅读并同意用户协议');
        return;
      }
  
      try {
        await GoogleSignin.hasPlayServices()
        const userInfo = await GoogleSignin.signIn()
        console.log("GoogleSignin hasPlayServicesxxx",userInfo)
  
        if (userInfo?.data?.idToken) {
          const { data, error } = await supabase.auth.signInWithIdToken({
            provider: 'google',
            token: userInfo.data.idToken,
          })
          console.log(error, data)
        } else {
          throw new Error('no ID token present!')
        }
      } catch (error: any) {
        console.log("GoogleSignin hasPlayServicesxxx error",error)
        if (error.code === statusCodes.SIGN_IN_CANCELLED) {
          // user cancelled the login flow
        } else if (error.code === statusCodes.IN_PROGRESS) {
          // operation (e.g. sign in) is in progress already
        } else if (error.code === statusCodes.PLAY_SERVICES_NOT_AVAILABLE) {
          // play services not available or outdated
        } else {
          // some other error happened
        }
      }
    
    };
  
    const createButtonGesture = (provider: 'google' | 'apple') => {
      return Gesture.Tap()
        .onBegin(() => {
          buttonScale.value = withSpring(0.95);
        })
        .onFinalize(() => {
          buttonScale.value = withSpring(1);
          if (!isLoading) {
            runOnJS(handleLogin)(provider); 
           //  handleLogin(provider);
          }
        });
    };
 const checkboxGesture = Gesture.Tap()
    .onBegin(() => {
      checkboxScale.value = withSpring(0.9);
    })
    .onFinalize(() => {
      checkboxScale.value = withSpring(1);
      runOnJS(setAgreedToTerms)(!agreedToTerms);
    });

  const buttonAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: buttonScale.value }],
  }));

  const checkboxAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: checkboxScale.value }],
  }));

  const fadeAnimatedStyle = useAnimatedStyle(() => ({
    opacity: fadeIn.value,
    transform: [
      {
        translateY: interpolate(fadeIn.value, [0, 1], [50, 0]),
      },
    ],
  }));


  if (isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
         {!isLoggedIn && (
      <View style={styles.content}>
      <View style={styles.header}>
        <Text style={styles.title}>欢迎回来</Text>
        <Text style={styles.subtitle}>请选择您喜欢的登录方式</Text>
      </View>

      <View style={styles.buttonContainer}>
        <GestureDetector gesture={createButtonGesture('google')}>
          <Animated.View style={buttonAnimatedStyle}>
            <TouchableOpacity 
              style={[styles.loginButton, styles.googleButton]}
              disabled={isLoading}
            >
              <View style={styles.buttonContent}>
                <Text style={styles.googleIcon}>G</Text>
                <Text style={styles.buttonText}>使用 Google 登录</Text>
              </View>
            </TouchableOpacity>
          </Animated.View>
        </GestureDetector>

        {Platform.OS === 'ios' && (
          <GestureDetector gesture={createButtonGesture('apple')}>
            <Animated.View style={buttonAnimatedStyle}>
              <TouchableOpacity 
                style={[styles.loginButton, styles.appleButton]}
                disabled={isLoading}
              >
                <View style={styles.buttonContent}>
                  <Text style={styles.appleIcon}></Text>
                  <Text style={[styles.buttonText, styles.appleButtonText]}>使用 Apple 登录</Text>
                </View>
              </TouchableOpacity>
            </Animated.View>
          </GestureDetector>
        )}
      </View>

      <View style={styles.footer}>
        <GestureDetector gesture={checkboxGesture}>
          <Animated.View style={[styles.checkboxContainer, checkboxAnimatedStyle]}>
            <View style={[styles.checkbox, agreedToTerms && styles.checkboxChecked]}>
              {agreedToTerms && <Text style={styles.checkmark}>✓</Text>}
            </View>
            <Text style={styles.checkboxText}>
              我已阅读并同意{' '}
              <Text style={styles.link}>用户协议</Text>
              {' '}和{' '}
              <Text style={styles.link}>隐私政策</Text>
            </Text>
          </Animated.View>
        </GestureDetector>
      </View>
    </View>
    )}
    {isLoggedIn && (
      <NavigationContainer>    
        <I18nextProvider i18n={i18n}>
        <Stack.Navigator initialRouteName="Main">
          <Stack.Screen name="PhotoView" component={PhotoViewScreen} options={{ headerShown: false }}/>
          <Stack.Screen name="Main" component={MainTabs} options={{ headerShown: false }} />
        </Stack.Navigator>
        </I18nextProvider>
      </NavigationContainer>    )}
    </GestureHandlerRootView>
  );
}
const styles = StyleSheet.create({
  container: {
    flex: 1,
    // backgroundColor: '#FEF3C7',
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: 24,
    paddingTop: 24,
  },
  content: {
    flex: 1,
    paddingHorizontal: 24,
    justifyContent: 'center',
    backgroundColor: 'white'
  },
  header: {
    alignItems: 'center',
    marginBottom: 48,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#92400E',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#A16207',
    textAlign: 'center',
    lineHeight: 24,
  },
  buttonContainer: {
    gap: 16,
    marginBottom: 32,
  },
  loginButton: {
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 24,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  buttonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  googleButton: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  appleButton: {
    backgroundColor: '#000000',
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#374151',
    marginLeft: 12,
  },
  appleButtonText: {
    color: '#FFFFFF',
  },
  googleIcon: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#4285F4',
    width: 20,
    textAlign: 'center',
  },
  appleIcon: {
    fontSize: 18,
    color: '#FFFFFF',
    width: 20,
    textAlign: 'center',
  },
  footer: {
    paddingBottom: 32,
  },
  checkboxContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingHorizontal: 8,
  },
  checkbox: {
    width: 20,
    height: 20,
    borderWidth: 2,
    borderColor: '#D97706',
    borderRadius: 4,
    marginRight: 12,
    marginTop: 2,
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkboxChecked: {
    backgroundColor: '#F59E0B',
    borderColor: '#F59E0B',
  },
  checkmark: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: 'bold',
  },
  checkboxText: {
    flex: 1,
    fontSize: 14,
    color: '#A16207',
    lineHeight: 20,
  },
  link: {
    color: '#D97706',
    fontWeight: '600',
    textDecorationLine: 'underline',
  },
  avatarContainer: {
    position: 'relative',
    marginBottom: 16,
  },
  avatar: {
    width: 100,
    height: 100,
    borderRadius: 50,
    borderWidth: 4,
    borderColor: '#F59E0B',
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 40,
    textAlign: 'center',
    textAlignVertical: 'center',
    includeFontPadding: false,
  },
  avatarPlaceholder: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: '#FED7AA',
    borderWidth: 4,
    borderColor: '#F59E0B',
    alignItems: 'center',
    justifyContent: 'center',
  },
  providerBadge: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#F59E0B',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 3,
    borderColor: '#FEF3C7',
  },
  providerText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: 'bold',
  },
  userName: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#92400E',
    marginBottom: 4,
    textAlign: 'center',
  },
  userEmail: {
    fontSize: 16,
    color: '#A16207',
    textAlign: 'center',
  },
  infoSection: {
    marginBottom: 32,
  },
  infoCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  infoItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#FEF3C7',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  infoContent: {
    flex: 1,
  },
  infoLabel: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 2,
  },
  infoValue: {
    fontSize: 16,
    color: '#111827',
    fontWeight: '500',
  },
  separator: {
    height: 1,
    backgroundColor: '#F3F4F6',
    marginVertical: 8,
  },
  actionsSection: {
    marginTop: 'auto',
    paddingBottom: 32,
  },
  signOutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderWidth: 1,
    borderColor: '#F87171',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  signOutText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#DC2626',
    marginLeft: 8,
  },
});
export default App;
