
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
} from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { getMembership } from '../api/teams/membership';
import { getHomeData } from '../api/teams/home';
import { getCheckIns } from '../api/teams/checkin';

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

const HomeScreen = ({ navigation }: { navigation: any }) => {
  const viewPhoto = (photoUrl: Checkin) => {
    navigation.navigate('PhotoView', { photoUrl });
  };
  const [checkinRecords, setCheckinRecords] = useState<Checkin[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [homeLoading, setHomeLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const { t } = useTranslation();
  const [teamMembership,setTeamMembership] = useState<TeamMembership>();
  const [homeData,setHomeData] = useState<HomeData>();
  
  useEffect(() => {
    const checkAuthState = async () => {
      const sessionString = await AuthBridge.getSession();
      if (sessionString) {

          const session = JSON.parse(sessionString);
          const membership = await getMembership(session)
          setLoading(true);
          setTeamMembership(membership.teamMember)  
          var jsonStr = JSON.stringify(membership.teamMember)
          await  AuthBridge.saveTeamInfo(jsonStr)
 
          setHomeLoading(true);
          const homeData = await getHomeData(session)
          setHomeData(homeData)
          setHomeLoading(false);
          const checkins = await getCheckIns(session)
          setCheckinRecords(checkins.today_checkins)
          console.log(checkins)
          setLoading(false);
      }
    };
     checkAuthState();
  }, []);
    const gotoMember = () => {
      navigation.navigate('Member')
    };



  return (
    <SafeAreaView style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerLeft}>
            <Text style={styles.title}>{teamMembership ? teamMembership.teams.name : t('teamCheckin')}</Text>
            <Text style={styles.subtitle}>{t('todayIs')} {new Date().toLocaleDateString()}</Text>
          </View>
        </View>

        {/* Stats Cards */}
        <View style={styles.statsContainer}>
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
            <Text style={styles.statNumber}>{homeData ? homeData.statistics.today_checkin_count : 0}</Text>
            <Text style={styles.statLabel}>{t('checkedIn')}</Text>
          </View>
          <View style={styles.statCard}>
            <View style={styles.statIconContainer}>
              <TrendingUp size={24} color="#f59e0b" />
            </View>
            <Text style={styles.statNumber}>{homeData ? calculatePercentage(homeData.statistics.today_checkin_count, homeData.statistics.total_members) : "0%"}</Text>
            <Text style={styles.statLabel}>{t('attendanceRate')}</Text>
          </View>
        </View>

        {/* Today's Photos */}
        
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Camera size={20} color="#374151" />
            <Text style={styles.sectionTitle}>{t('todaysPhotos')}</Text>
          </View>
           <View style={styles.todayPhotosContent}>   
             {homeLoading && (
                  <Text>{t('loading')}</Text>
               )}</View>
            <ScrollView 
              horizontal 
              showsHorizontalScrollIndicator={false} 
              style={styles.photosScroll}
              contentContainerStyle={styles.todayPhotosContent}
            >
              
              { homeData?.today_checkins.map((record, index) => (
                <TouchableOpacity key={index} style={styles.photoContainer}     onPress={() => viewPhoto(record)}>
                  <Image source={{ uri:record.image_url }} style={styles.photo} />
                </TouchableOpacity>
              ))}
                       
            </ScrollView>
   
        </View>

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
  todayPhotosContent: {
    paddingHorizontal: 4,
    width:"100%",
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
});
export default HomeScreen;



