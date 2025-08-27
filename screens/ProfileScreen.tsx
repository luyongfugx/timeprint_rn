import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView,   Image, Alert, SafeAreaView, Platform } from 'react-native';
import { User, LogOut, Mail, Shield } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { supabase } from '../api/supabase';
import { GoogleSignin, statusCodes } from '@react-native-google-signin/google-signin';
import LinearGradient from 'react-native-linear-gradient';
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
  const signOutGesture = Gesture.Tap()
  .onBegin(() => {
    buttonScale.value = withSpring(0.95);
  })
  .onFinalize(() => {
    buttonScale.value = withSpring(1);
    runOnJS(handleLogout)();
  });




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



  return (
    <SafeAreaView style={styles.container}>
      {!isLoggedIn && (
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
    </Animated.View>)}
    {isLoggedIn && user && (
    <ScrollView contentContainerStyle={styles.scrollContent}>
        <Animated.View 
          style={styles.header}
          entering={FadeInUp.delay(200).springify()}
        >
          <View style={styles.avatarContainer}>
            {user.avatar ? (
              <Image source={{ uri: user.avatar }} style={styles.avatar} />
            ) : (
              <View style={styles.avatarPlaceholder}>
                <View style={styles.avatar}>
               <Text style={styles.avatarText}>
                 {user.user_metadata?.name?.charAt(0) || user.email?.charAt(0) || 'U'}
              </Text>
            </View>
              </View>
            )}
            <View style={styles.providerBadge}>
              <Text style={styles.providerText}>
                {user.provider === 'google' ? 'G' : ''}
              </Text>
            </View>
          </View>
          <Text style={styles.userName}>{user.name}</Text>
          <Text style={styles.userEmail}>{user.email}</Text>
        </Animated.View>
  
        <Animated.View 
          style={styles.infoSection}
          entering={FadeInUp.delay(400).springify()}
        >
          <View style={styles.infoCard}>
            <View style={styles.infoItem}>
              <View style={styles.iconContainer}>
                <Mail size={20} color="#A16207" />
              </View>
              <View style={styles.infoContent}>
                <Text style={styles.infoLabel}>昵称</Text>
                <Text style={styles.infoValue}>{user.user_metadata?.name || user.email || t('user')}</Text>
              </View>
            </View>

            <View style={styles.separator} />

            {/* <View style={styles.infoItem}>
              <View style={styles.iconContainer}>
                <Shield size={20} color="#A16207" />
              </View>
              <View style={styles.infoContent}>
                <Text style={styles.infoLabel}>账户类型</Text>
                <Text style={styles.infoValue}>
                  {user.provider === 'google' ? 'Google 账户' : 'Apple 账户'}
                </Text>
              </View>
            </View> */}
          </View>
        </Animated.View>

        <Animated.View 
          style={styles.actionsSection}
          entering={FadeInDown.delay(600).springify()}
        >
          <GestureDetector gesture={signOutGesture}>
            <Animated.View style={buttonAnimatedStyle}>
              <TouchableOpacity style={styles.signOutButton}>
                <LogOut size={20} color="#DC2626" />
                <Text style={styles.signOutText}>退出登录</Text>
              </TouchableOpacity>
            </Animated.View>
          </GestureDetector>
        </Animated.View>
      </ScrollView>)}
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



export default ProfileScreen;