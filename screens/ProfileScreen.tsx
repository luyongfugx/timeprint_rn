import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Switch, Alert } from 'react-native';
import { ArrowBigLeft } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { supabase } from '../api/supabase';

const ProfileScreen = () => {
  const { t } = useTranslation();
  const handleLogin = async () => {
    const email ="luyf"
    const password ="luyf"
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
   Alert.alert(error?.message??"")
  
  };

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>{t('profile')}</Text>
      </View>

      {/* 用户信息卡片 */}
      <View style={styles.profileCard}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>勇福</Text>
        </View>
        <View style={styles.userInfo}>
          <Text style={styles.userName}>卢勇福</Text>
          <Text style={styles.levelTag}>{t('achievementLevel', { level: 3 })}</Text>
        </View>
        <TouchableOpacity style={styles.certificateButton}  onPress={handleLogin}>
          <Text style={styles.certificateText}>{t('workCertificate')}</Text>
          <Text style={styles.certificateLink}>{t('view')}</Text>
        </TouchableOpacity>
      </View>

      {/* 列表项 */}
      <Item label={t('industry')} />
      <Item label={t('member')} right={<Text style={styles.vipTag}>{t('vip')}</Text>} rightText={t('vipBenefits')} />
      <Item label={t('myOrders')} rightText={t('invoiceAvailable')} />

      <Item label={t('id')} rightText="4805280374" copy />
      <Item label={t('phoneNumber')} rightText="13811333363" linkText={t('change')} />
      <Item label={t('wechatBinding')} rightText={t('bound')} linkText={t('unbind')} />
      <Item label={t('accountCancellation')} rightText={t('cancellationWarning')} />

      {/* 退出按钮 */}
      <TouchableOpacity style={styles.logoutBtn}>
        <Text style={styles.logoutText}>{t('logout')}</Text>
      </TouchableOpacity>
    </ScrollView>
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
  logoutBtn: {
    backgroundColor: '#fff',
    paddingVertical: 16,
    marginTop: 20,
    alignItems: 'center',
  },
  logoutText: {
    color: '#E53935',
    fontSize: 16,
  },
});

export default ProfileScreen;
