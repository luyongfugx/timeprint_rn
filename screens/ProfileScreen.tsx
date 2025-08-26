import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Switch, Alert, SafeAreaView, Platform } from 'react-native';
import { ArrowBigLeft } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { supabase } from '../api/supabase';
import { GoogleSignin, statusCodes } from '@react-native-google-signin/google-signin';
import LinearGradient from 'react-native-linear-gradient';
import Animated, { 
  useAnimatedStyle, 
  withSpring, 
  withTiming,
  useSharedValue,
  interpolate
} from 'react-native-reanimated';
import { GestureDetector, Gesture } from 'react-native-gesture-handler';

const ProfileScreen = () => {
  const { t } = useTranslation();
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [user, setUser] = useState<any>(null);

  const [agreedToTerms, setAgreedToTerms] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const buttonScale = useSharedValue(1);
  const checkboxScale = useSharedValue(1);
  const fadeIn = useSharedValue(0);

 

  useEffect(() => {
    fadeIn.value = withTiming(1, { duration: 800 });
    // 检查当前登录状态
    const checkAuthState = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      setIsLoggedIn(!!session);
      setUser(session?.user || null);
    };

    checkAuthState();

    // 监听认证状态变化
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setIsLoggedIn(!!session);
        console.log("onAuthStateChange" ,session)
        setUser(session?.user || null);
      }
    );

    return () => subscription.unsubscribe();
  }, []);


  const createButtonGesture = (provider: 'google' | 'apple') => {
    return Gesture.Tap()
      .onBegin(() => {
        buttonScale.value = withSpring(0.95);
      })
      .onFinalize(() => {
        buttonScale.value = withSpring(1);
        if (!isLoading) {
          handleLogin(provider);
        }
      });
  };

  const checkboxGesture = Gesture.Tap()
    .onBegin(() => {
      checkboxScale.value = withSpring(0.9);
    })
    .onFinalize(() => {
      checkboxScale.value = withSpring(1);
      setAgreedToTerms(!agreedToTerms);
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



  const handleLogin = async () => {
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

  const handleLogout = async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) {
        console.error('Error signing out:', error);
      }
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };


  return (
    <SafeAreaView style={styles.container}>
    <Animated.View style={[styles.content, fadeAnimatedStyle]}>
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
    </Animated.View>
  </SafeAreaView>
    // <View style={styles.container}>
    //   <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
    //     {/* Header */}
    //     <View style={styles.header}>
    //       <Text style={styles.headerTitle}>{t('profile')}</Text>
    //     </View>

    //     {/* 用户信息卡片 - 只在登录状态下显示 */}
    //     {isLoggedIn && user && (
    //       <View style={styles.profileCard}>
    //         <View style={styles.avatar}>
    //           <Text style={styles.avatarText}>
    //             {user.user_metadata?.name?.charAt(0) || user.email?.charAt(0) || 'U'}
    //           </Text>
    //         </View>
    //         <View style={styles.userInfo}>
    //           <Text style={styles.userName}>
    //             {user.user_metadata?.name || user.email || t('user')}
    //           </Text>
    //           {/* <Text style={styles.levelTag}>{t('achievementLevel', { level: 3 })}</Text> */}
    //         </View>
    //         {/* <TouchableOpacity style={styles.certificateButton} >
    //           <Text style={styles.certificateText}>{t('workCertificate')}</Text>
    //           <Text style={styles.certificateLink}>{t('view')}</Text>
    //         </TouchableOpacity> */}
    //       </View>
    //     )}

    //     {/* 列表项 */}
    //     {/* <Item label={t('industry')} />
    //     <Item label={t('member')} right={<Text style={styles.vipTag}>{t('vip')}</Text>} rightText={t('vipBenefits')} />
    //     <Item label={t('myOrders')} rightText={t('invoiceAvailable')} />

    //     <Item label={t('id')} rightText="4805280374" copy />
    //     <Item label={t('phoneNumber')} rightText="13811333363" linkText={t('change')} />
    //     <Item label={t('wechatBinding')} rightText={t('bound')} linkText={t('unbind')} />
    //     <Item label={t('accountCancellation')} rightText={t('cancellationWarning')} /> */}
    //   </ScrollView>

    //   {/* 登录/退出按钮 - 放在底部 */}
    //   <TouchableOpacity 
    //     style={styles.bottomButton}  
    //     onPress={isLoggedIn ? handleLogout : handleLogin}
    //   >
    //     <Text style={styles.bottomButtonText}>
    //       {isLoggedIn ? t('logout') : t('login')}
    //     </Text>
    //   </TouchableOpacity>
    // </View>
  );
};

// const Item = ({
//   label,
//   rightText,
//   right,
//   copy,
//   linkText,
// }: {
//   label: string;
//   rightText?: string;
//   right?: React.ReactNode;
//   copy?: boolean;
//   linkText?: string;
// }) => {
//   const { t } = useTranslation()
//   return (
//   <View style={styles.itemRow}>
//     <Text style={styles.itemLabel}>{label}</Text>
//     <View style={styles.itemRight}>
//       {rightText && <Text style={styles.itemValue}>{rightText}</Text>}
//       {right}
//       {linkText && <Text style={styles.linkText}>{linkText}</Text>}
//       {copy && <Text style={styles.copyText}>{t('copy')}</Text>}
//     </View>
//   </View>
// )};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FEF3C7',
  },
  content: {
    flex: 1,
    paddingHorizontal: 24,
    justifyContent: 'center',
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
});

const styles2 = StyleSheet.create({
  container: {
    backgroundColor: '#f9f9f9',
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 100, // 为底部按钮留出空间
  },
  header: {
    flexDirection: 'row',
    padding: 16,
    alignItems: 'center',
    backgroundColor: '#fff',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginLeft: 8,
  },
  profileCard: {
    backgroundColor: '#fff',
    padding: 16,
    flexDirection: 'column',
    marginBottom: 8,
  },
  avatar: {
    backgroundColor: '#5B8EF2',
    width: 48,
    height: 48,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 16,
  },
  userInfo: {
    marginTop: 8,
  },
  userName: {
    fontSize: 16,
    fontWeight: '500',
  },
  levelTag: {
    marginTop: 4,
    fontSize: 12,
    color: '#B07B00',
    backgroundColor: '#FFF2D4',
    alignSelf: 'flex-start',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  certificateButton: {
    marginTop: 12,
    backgroundColor: '#4479f6',
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 10,
    borderRadius: 6,
  },
  certificateText: {
    color: '#fff',
    fontSize: 14,
  },
  certificateLink: {
    color: '#fff',
    fontWeight: 'bold',
  },
  itemRow: {
    backgroundColor: '#fff',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  itemLabel: {
    fontSize: 15,
    color: '#333',
  },
  itemRight: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  itemValue: {
    color: '#666',
    fontSize: 14,
    marginRight: 6,
  },
  copyText: {
    color: '#007AFF',
    fontSize: 14,
  },
  linkText: {
    color: '#007AFF',
    fontSize: 14,
    marginLeft: 6,
  },
  vipTag: {
    backgroundColor: '#FFDD99',
    paddingHorizontal: 4,
    paddingVertical: 2,
    marginRight: 4,
    fontSize: 12,
    borderRadius: 4,
  },
  bottomButton: {
    position: 'absolute',
    bottom: 30,
    left: 16,
    right: 16,
    backgroundColor: '#fff',
    paddingVertical: 16,
    alignItems: 'center',
    borderRadius: 8,
  },
  bottomButtonText: {
    color: '#E53935',
    fontSize: 16,
    fontWeight: '600',
  },
});

export default ProfileScreen;