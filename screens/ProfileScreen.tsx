import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Switch, Alert } from 'react-native';
import { ArrowBigLeft } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { supabase } from '../api/supabase';
import { GoogleSignin, statusCodes } from '@react-native-google-signin/google-signin';

const ProfileScreen = () => {
  const { t } = useTranslation();
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [user, setUser] = useState<any>(null);

  useEffect(() => {
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

  const handleLogin = async () => {
  GoogleSignin.configure({
    scopes: ['https://www.googleapis.com/auth/drive.readonly'],
    webClientId: '401431549807-5jq8d5vicunav6osh0lcof33i260nb64.apps.googleusercontent.com',
  })

    try {
      await GoogleSignin.hasPlayServices()
      console.log("GoogleSignin hasPlayServicesaaaaa")
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
    <View style={styles.container}>
      <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.headerTitle}>{t('profile')}</Text>
        </View>

        {/* 用户信息卡片 - 只在登录状态下显示 */}
        {isLoggedIn && user && (
          <View style={styles.profileCard}>
            <View style={styles.avatar}>
              <Text style={styles.avatarText}>
                {user.user_metadata?.name?.charAt(0) || user.email?.charAt(0) || 'U'}
              </Text>
            </View>
            <View style={styles.userInfo}>
              <Text style={styles.userName}>
                {user.user_metadata?.name || user.email || t('user')}
              </Text>
              {/* <Text style={styles.levelTag}>{t('achievementLevel', { level: 3 })}</Text> */}
            </View>
            {/* <TouchableOpacity style={styles.certificateButton} >
              <Text style={styles.certificateText}>{t('workCertificate')}</Text>
              <Text style={styles.certificateLink}>{t('view')}</Text>
            </TouchableOpacity> */}
          </View>
        )}

        {/* 列表项 */}
        {/* <Item label={t('industry')} />
        <Item label={t('member')} right={<Text style={styles.vipTag}>{t('vip')}</Text>} rightText={t('vipBenefits')} />
        <Item label={t('myOrders')} rightText={t('invoiceAvailable')} />

        <Item label={t('id')} rightText="4805280374" copy />
        <Item label={t('phoneNumber')} rightText="13811333363" linkText={t('change')} />
        <Item label={t('wechatBinding')} rightText={t('bound')} linkText={t('unbind')} />
        <Item label={t('accountCancellation')} rightText={t('cancellationWarning')} /> */}
      </ScrollView>

      {/* 登录/退出按钮 - 放在底部 */}
      <TouchableOpacity 
        style={styles.bottomButton}  
        onPress={isLoggedIn ? handleLogout : handleLogin}
      >
        <Text style={styles.bottomButtonText}>
          {isLoggedIn ? t('logout') : t('login')}
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const Item = ({
  label,
  rightText,
  right,
  copy,
  linkText,
}: {
  label: string;
  rightText?: string;
  right?: React.ReactNode;
  copy?: boolean;
  linkText?: string;
}) => {
  const { t } = useTranslation()
  return (
  <View style={styles.itemRow}>
    <Text style={styles.itemLabel}>{label}</Text>
    <View style={styles.itemRight}>
      {rightText && <Text style={styles.itemValue}>{rightText}</Text>}
      {right}
      {linkText && <Text style={styles.linkText}>{linkText}</Text>}
      {copy && <Text style={styles.copyText}>{t('copy')}</Text>}
    </View>
  </View>
)};

const styles = StyleSheet.create({
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