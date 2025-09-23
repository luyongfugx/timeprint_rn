
import React, { useState,useEffect } from 'react';
import {   View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  TouchableOpacity,
  NativeModules,
  Alert } from 'react-native';
import { launchImageLibrary } from 'react-native-image-picker';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  Users,
  Clock,
  Camera,
  MapPin,
  Calendar,
  TrendingUp,
  X,
} from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { useRoute } from '@react-navigation/native';
import { getUserInfo } from '../api/teams/user';
const { AuthBridge } = NativeModules;

// 格式化 Unix 时间戳（毫秒）为 YYYY-MM-DD HH:mm:ss 格式
const formatUnixTimestamp = (timestamp: number): string => {
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
};

// 计算百分比并格式化为 "6%" 格式
const calculatePercentage = (numerator: number, denominator: number): string => {
  if (denominator === 0) return '0%';
  const percentage = (numerator / denominator) * 100;
  return `${Math.round(percentage)}%`;
};

const UserInfoScreen = ({ navigation }: { navigation: any }) => {
  const route = useRoute();
  const { userId } = route.params as { userId: String };
  const [checkinRecords, setCheckinRecords] = useState<Checkin[]>([]);
  const [userInfo, setUserInfo] = useState<UserInfo>();
  
  const [loading, setLoading] = useState<boolean>(true);
  const { t } = useTranslation();
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    const checkAuthState = async () => {
      const sessionString = await AuthBridge.getSession();
      if (sessionString) {
          const session = JSON.parse(sessionString)
          setLoading(true);
          const data = await getUserInfo(session,userId)
          setCheckinRecords(data.checkins)
          setUserInfo(data.user)
          setLoading(false);
      }
    };
     checkAuthState();
  }, []);
  const viewPhoto = (photoUrl: Checkin) => {
    navigation.navigate('PhotoView', { photoUrl });
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}  
      style={{width:"100%"}}  
             >
        {/* Header */}
        {/* <View style={styles.header}>
          <View style={styles.headerLeft}>
            <Text style={styles.title}>{teamMembership ? teamMembership.teams.name : t('teamCheckin')}</Text>
            <Text style={styles.subtitle}>{t('todayIs')} {new Date().toLocaleDateString()}</Text>
          </View>
        </View> */}

        {/* Stats Cards */}
        {/* <View style={styles.statsContainer}>
          <View style={styles.statCard} >
            <View style={styles.statIconContainer}>
            <TouchableOpacity onPress={gotoMember} >
              <Users size={24} color="#3b82f6" />
              </TouchableOpacity>
            </View>
            <TouchableOpacity onPress={gotoMember} >
            <Text style={styles.statNumber}>{homeData ? homeData.statistics.total_members : 0}</Text>
            <Text style={styles.statLabel}>{t('teamMembers')}</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.statCard}>
            <View style={styles.statIconContainer}>
              <Clock size={24} color="#10b981" />
            </View>
            <Text style={styles.statNumber}>{homeData ? homeData.statistics.today_checkin_users : 0}</Text>
            <Text style={styles.statLabel}>{t('checkedIn')}</Text>
          </View>
          <View style={styles.statCard}>
            <View style={styles.statIconContainer}>
              <TrendingUp size={24} color="#f59e0b" />
            </View>
            <Text style={styles.statNumber}>{homeData ? calculatePercentage(homeData.statistics.today_checkin_users, homeData.statistics.total_members) : "0%"}</Text>
            <Text style={styles.statLabel}>{t('attendanceRate')}</Text>
          </View>
        </View> */}
       {userInfo && (
      <View style={styles.header}>

        <View style={styles.avatarContainer}>
          <Image
            source={{ uri: userInfo.user_avatar }}
            style={styles.avatar}
          />        
          <View style={{ flex: 1, marginLeft: 12 }}>
          <Text style={styles.name}>{userInfo.user_name}</Text>
          <Text style={styles.subtitle_name}>{userInfo.user_email}</Text>
        </View>
        </View>

      </View>
      )}
        {/* Checkin Records */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Calendar size={20} color="#374151" />
            <Text style={styles.sectionTitle}>{t('checkinRecords')}</Text>
          </View>
          {loading ? (
            <Text>{t('loading')}</Text>
          ) : error ? (
            <Text style={{ color: 'red' }}>{error}</Text>
          ) : 
            checkinRecords.map((record: Checkin) => (
            <View key={record.id} style={styles.recordCard}>
              <View style={styles.recordHeader}>
                <View style={styles.memberInfo}>
                 
                  <View style={styles.memberDetails}>
                  <View style={styles.timeLocationRow}>
                    <Image source={{ uri: record.user_avatar }} style={styles.memberAvatar} />
                    <Text style={styles.memberName}>{record.user_name}</Text>
                  </View>
                    <View style={styles.timeLocationContainer}>

                    <TouchableOpacity 
                    style={styles.photoWrapper}
                    onPress={() => viewPhoto(record)}
                  >
                   <Image source={{ uri: record.image_url }} style={styles.checkinPhoto} /> 
   
                  </TouchableOpacity>
                      <View style={styles.timeLocationRow}>
                      <Clock size={14} color="#6b7280" />
                      <Text style={styles.timeText}>{formatUnixTimestamp(record.created_at)}</Text>
                      </View>
                      <View style={styles.timeLocationRow}>
                      <MapPin size={14} color="#6b7280" />
                      <Text style={styles.locationText}>{record.location}</Text>
                      </View>
                    </View>
                  </View>
                </View>
                {/* <View style={[styles.statusBadge, { backgroundColor: getStatusColor(record.status) }]}>
                  <Text style={styles.statusText}>{getStatusText(record.status)}</Text>
                </View> */}
              </View>
              <ScrollView 
                horizontal 
                showsHorizontalScrollIndicator={false} 
                style={styles.photosContainer}
                contentContainerStyle={styles.photosContent}
              >
                {/* {record.photos.map((photo: string, index: number) => ( */}
                  <TouchableOpacity 
                    style={styles.photoWrapper}
                    onPress={() => viewPhoto(record)}
                  >
                    {/* <Image source={{ uri: record.image_url }} style={styles.checkinPhoto} /> */}
                    {/* {record.photos.length > 1 && (
                      <View style={styles.photoCounter}>
                        <Text style={styles.photoCounterText}>
                          {index + 1}/{record.photos.length}
                        </Text>
                      </View>
                    )} */}
                  </TouchableOpacity>
                {/* ))} */}
              </ScrollView>
            </View>
          ))}
        </View>
      </ScrollView>
    </SafeAreaView >
  );
};

// const styles = StyleSheet.create({
//   container: {
//     flex: 1,
//     justifyContent: 'center',
//     alignItems: 'center',
//     backgroundColor: '#f0f0f0',
//   },
//   text: {
//     fontSize: 24,
//     fontWeight: 'bold',
//   },
// });

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width:"100%",
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f8fafc',
  },
  text: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  header: {
    padding: 20,
    paddingBottom: 10,
    width:"100%"
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#1f2937',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 16,
    color: '#6b7280',
  },
  statsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingBottom: 20,
    gap: 12,
    width:"100%"
  },
  statCard: {
    flex: 1,
    backgroundColor: '#ffffff',
    padding: 16,
    borderRadius: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
    justifyContent: 'center',
  },
  statIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#f3f4f6',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  statNumber: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1f2937',
    marginBottom: 4,
    textAlign: 'center',
  },
  statLabel: {
    fontSize: 12,
    color: '#6b7280',
    textAlign: 'center',
  },
  section: {
    paddingHorizontal: 20,
    paddingBottom: 24,
    width:"100%"
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
    gap: 8,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#374151',
  },
  photosScroll: {
    marginHorizontal: -4,
  },
  closeButton: {
    position: 'absolute',
    top: 20,
    left: 20,
    zIndex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    borderRadius: 20,
    padding: 10,
  },
  todayPhotosLoading:{
    paddingHorizontal: 4,
    width:"100%",
  },
  teamMembershipContent:{
    width:"100%",
  },
  todayPhotosContent: {
    paddingHorizontal: 4,
  },
  photoContainer: {
    marginHorizontal: 4,
  },
  photo: {
    width: 120,
    height: 120,
    borderRadius: 12,
  },
  recordCard: {
    backgroundColor: '#ffffff',
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  recordHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  memberInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  memberAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    marginRight: 12,
  },
  memberDetails: {
    flex: 1,
  },
  memberName: {
    lineHeight:48,
    fontSize: 16,
    fontWeight: '600',
    color: '#1f2937',
    marginBottom: 4,
  },
  timeLocationContainer: {
    flexDirection: 'column',
    alignItems: 'flex-start',
    gap: 4,
  },
  timeLocationRow: {
    flexDirection: 'row',
    marginRight:8,
    alignItems: 'flex-start',
    gap: 4,
  },
  timeText: {
    fontSize: 12,
    color: '#6b7280',
    marginRight: 8,
  },
  name: {
    fontSize: 20,
    fontWeight: "700",
    color: "#000",
  },
  subtitle_name: {
    fontSize: 14,
    color: "#666",
  },
  locationText: {
    fontSize: 12,
    color: '#6b7280',
    overflow: 'hidden',
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  statusText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#ffffff',
  },
  photosContainer: {
    marginHorizontal: -4,
  },
  photosContent: {
    paddingHorizontal: 4,
  },
  photoWrapper: {
    position: 'relative',
    marginHorizontal: 4,
  },
  checkinPhoto: {
    width: 160,
    height: 160,
    borderRadius: 12,
  },
  photoCounter: {
    position: 'absolute',
    top: 8,
    right: 8,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  photoCounterText: {
    fontSize: 12,
    color: '#ffffff',
    fontWeight: '600',
  },
  headerLeft: {
    flex: 1,
  },
  cameraButton: {
    position: 'absolute',
    top: 20,
    right: 20,
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#f3f4f6',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  avatarContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 4,
  },
  avatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
  },
});
export default UserInfoScreen;



