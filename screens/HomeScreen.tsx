
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  TouchableOpacity,
  NativeModules,
  Alert,
  TextInput
} from 'react-native';
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
import { createTeam, getTeamInfoById, joinTeam } from '../api/teams/team';

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
  const [teamMembership, setTeamMembership] = useState<TeamMembership>();
  const [homeData, setHomeData] = useState<HomeData>();
  const [hasTeam, setHasTeam] = useState<boolean>(true);
  // 标签页状态
  const [activeTab, setActiveTab] = useState<'create' | 'join'>('create');

  // 创建团队表单状态
  const [formData, setFormData] = useState({
    name: '',
    address: '',
    description: ''
  });
  const loadHomeData = async () => {
    const sessionString = await AuthBridge.getSession();
    if (sessionString) {

      const session = JSON.parse(sessionString);
      try {
        setLoading(true);
        const membership = await getMembership(session)
        if (!membership.teamMember) { //如果没有团队
          setLoading(false);
          setHasTeam(false)
        }
        else {
          setTeamMembership(membership.teamMember)
          var jsonStr = JSON.stringify(membership.teamMember)
          await AuthBridge.saveTeamInfo(jsonStr)
          setHomeLoading(true);
          const homeData = await getHomeData(session)
          setHomeData(homeData)
          setHomeLoading(false);
          const checkins = await getCheckIns(session)
          setCheckinRecords(checkins.today_checkins)
          setLoading(false);
        }

      }
      catch (e) {

      }
    }
  };
  useEffect(() => {
    loadHomeData();
  }, []);
  const gotoMember = () => {
    navigation.navigate('Member')
  };

  const [createLoading, setCreateLoading] = useState(false);

  // 加入团队表单状态
  const [teamId, setTeamId] = useState('');
  const [teamInfo, setTeamInfo] = useState<any>(null);
  const [searchLoading, setSearchLoading] = useState(false);
  const [joinLoading, setJoinLoading] = useState(false);

  const handleCreateSubmit = async () => {
    if (!formData.name.trim()) {
      Alert.alert(t('error'), t('teamNameRequired'));
      return;
    }

    setCreateLoading(true);
    try {
      // 这里添加创建团队的 API 调用
      const sessionString = await AuthBridge.getSession();
      if (sessionString) {
          const session = JSON.parse(sessionString);
          const teamData = await createTeam(session,formData);
          if(teamData.status == 200){
            Alert.alert(t('success'), t('teamCreatedSuccess'));
            setHasTeam(true);
            loadHomeData() //重新获取数据
          }
          else {
            Alert.alert(t('error'), t('teamSearchFailed'));
          }

        }

    } catch (error) {
      Alert.alert(t('error'), t('teamCreatedFailed'));
    } finally {
      setCreateLoading(false);
    }
  };

  const handleSearchTeam = async () => {
    if (!teamId.trim()) {
      Alert.alert(t('error'), t('teamIdRequired'));
      return;
    }

    setSearchLoading(true);
    try {
      const sessionString = await AuthBridge.getSession();
      if (sessionString) {
        const session = JSON.parse(sessionString);
        const teamData = await getTeamInfoById(session,teamId);

        if(teamData.status == 200){
          setTeamInfo(teamData.data);
        }
        else {
          Alert.alert(t('error'), t('teamSearchFailed'));
        }
      }
    } catch (error) {
      Alert.alert(t('error'), t('teamSearchFailed'));
    } finally {
      setSearchLoading(false);
    }
  };

  const handleJoinTeam = async () => {
    if (!teamInfo) {
      Alert.alert(t('error'), t('searchTeamInfoFirst'));
      return;
    }
    setJoinLoading(true);
    try {
      const sessionString = await AuthBridge.getSession();
      if (sessionString) {
          const session = JSON.parse(sessionString);
      // 这里添加加入团队的 API 调用
        const joinData =    await joinTeam(session,teamInfo.id);
        console.log(joinData)
        if(joinData.status == 200){
          Alert.alert(t('success'), t('teamJoinSuccess'));
          setHasTeam(true);
        }
        else {
          Alert.alert(t('error'), t('teamJoinFailed'));
        }
      }

    } catch (error) {
      Alert.alert(t('error'), t('teamJoinFailed'));
      setJoinLoading(false);
    } finally {
      setJoinLoading(false);
    }
  };
  return (
    <SafeAreaView style={styles.container}>
      {!hasTeam && (
        <ScrollView
          style={styles.scrollView}
          contentContainerStyle={styles.tabsContainer}
          keyboardShouldPersistTaps="handled"
          keyboardDismissMode="on-drag"
        >
          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <Text style={styles.cardTitle}>{t('teamSetup')}</Text>
              <Text style={styles.cardDescription}>{t('createOrJoinTeam')}</Text>
              
              {/* 标签页切换 */}
              <View style={styles.tabButtons}>
                <TouchableOpacity 
                  style={[styles.tabButton, activeTab === 'create' && styles.tabButtonActive]}
                  onPress={() => setActiveTab('create')}
                >
                  <Text style={[styles.tabButtonText, activeTab === 'create' && styles.tabButtonTextActive]}>
                    {t('createTeam')}
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity 
                  style={[styles.tabButton, activeTab === 'join' && styles.tabButtonActive]}
                  onPress={() => setActiveTab('join')}
                >
                  <Text style={[styles.tabButtonText, activeTab === 'join' && styles.tabButtonTextActive]}>
                    {t('joinTeam')}
                  </Text>
                </TouchableOpacity>
              </View>
            </View>

            <View style={styles.cardContent}>
              <View style={{ display: activeTab === 'create' ? 'flex' : 'none', flex: 1 }}>
                <View style={styles.tabContent}>
                  <View style={styles.inputGroup}>
                    <Text style={styles.label}>{t('teamName')} *</Text>
                    <TextInput
                      style={styles.input}
                      placeholder={t('enterTeamName')}
                      value={formData.name}
                      onChangeText={(text) => setFormData(prev => ({ ...prev, name: text }))}
                      returnKeyType="done"

                    />
                  </View>

                  <View style={styles.inputGroup}>
                    <Text style={styles.label}>{t('teamAddress')}</Text>
                    <TextInput
                      style={styles.input}
                      placeholder={t('enterTeamAddress')}
                      value={formData.address}
                      onChangeText={(text) => setFormData(prev => ({ ...prev, address: text }))}
                      returnKeyType="done"
                      blurOnSubmit={false}
                    />
                  </View>

                  <View style={styles.inputGroup}>
                    <Text style={styles.label}>{t('teamDescription')}</Text>
                    <TextInput
                      style={[styles.input, styles.textarea]}
                      placeholder={t('enterTeamDescription')}
                      value={formData.description}
                      onChangeText={(text) => setFormData(prev => ({ ...prev, description: text }))}
                      multiline
                      numberOfLines={3}
                      returnKeyType="done"
                      blurOnSubmit={false}
                    />
                  </View>

                  <TouchableOpacity
                    style={[styles.submitButton, createLoading && styles.submitButtonDisabled]}
                    onPress={handleCreateSubmit}
                    disabled={createLoading}
                  >
                    <Text style={styles.submitButtonText}>
                      {createLoading ? t('creating') : t('createTeam')}
                    </Text>
                  </TouchableOpacity>
                </View>
              </View>
              <View style={{ display: activeTab === 'join' ? 'flex' : 'none', flex: 1 }}>
                <View style={styles.tabContent}>
                  <View style={styles.inputGroup}>
                    <Text style={styles.label}>{t('teamId')} *</Text>
                    <View style={styles.searchContainer}>
                      <TextInput
                        style={[styles.input, styles.searchInput]}
                        placeholder={t('enterTeamId')}
                        value={teamId}
                        onChangeText={setTeamId}
                        returnKeyType="done"
                      />
                      <TouchableOpacity 
                        style={[styles.searchButton, searchLoading && styles.searchButtonDisabled]}
                        onPress={handleSearchTeam}
                        disabled={searchLoading}
                      >
                        <Text style={styles.searchButtonText}>
                          {searchLoading ? t('searching') : t('search')}
                        </Text>
                      </TouchableOpacity>
                    </View>
                  </View>

                  {teamInfo && (
                    <View style={styles.teamInfoCard}>
                      <Text style={styles.teamInfoTitle}>{t('teamInfo')}</Text>
                      <View style={styles.teamInfoItem}>
                        <Text style={styles.teamInfoLabel}>{t('teamNameLabel')}</Text>
                        <Text style={styles.teamInfoValue}>{teamInfo.name}</Text>
                      </View>
                      <View style={styles.teamInfoItem}>
                        <Text style={styles.teamInfoLabel}>{t('teamDescriptionLabel')}</Text>
                        <Text style={styles.teamInfoValue}>{teamInfo.description}</Text>
                      </View>
                      <View style={styles.teamInfoItem}>
                        <Text style={styles.teamInfoLabel}>{t('memberCountLabel')}</Text>
                        <Text style={styles.teamInfoValue}>{teamInfo.memberCount}{t('people')}</Text>
                      </View>
                    </View>
                  )}

                  <TouchableOpacity
                    style={[styles.submitButton, (!teamInfo || joinLoading) && styles.submitButtonDisabled]}
                    onPress={handleJoinTeam}
                    disabled={!teamInfo || joinLoading}
                  >
                      <Text style={styles.submitButtonText}>
                        {joinLoading ? t('joining') : t('confirmJoin')}
                      </Text>
                  </TouchableOpacity>
                </View>
              </View>
            </View>
          </View>
        </ScrollView>
      )}
      {hasTeam &&
        <ScrollView showsVerticalScrollIndicator={false}
          style={{ width: "100%" }}
        >
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
          </View>

          {/* Today's Photos */}

          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <Camera size={20} color="#374151" />
              <Text style={styles.sectionTitle}>{t('todaysPhotos')}</Text>
            </View>
            <View style={styles.todayPhotosLoading}>
              {homeLoading && (
                <Text>{t('loading')}</Text>
              )}
                   {(!homeData  || homeData.today_checkins?.length <=0) &&  !homeLoading &&      
               <Text>{t('nodata')}</Text>
               }
              </View>
          
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              style={styles.photosScroll}
              contentContainerStyle={styles.todayPhotosContent}
            >
         
              {homeData?.today_checkins.map((record, index) => (
                <TouchableOpacity key={index} style={styles.photoContainer} onPress={() => viewPhoto(record)}>
                  <Image source={{ uri: record.image_url }} style={styles.photo} />
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
            {(!checkinRecords || checkinRecords?.length <=0) &&  !loading &&      
               <Text>{t('nodata')}</Text>}
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
      }
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
    width: "100%",
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
    width: "100%"
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
    width: "100%"
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
    width: "100%"
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
  todayPhotosLoading: {
    paddingHorizontal: 4,
    width: "100%",
  },
  teamMembershipContent: {
    width: "100%",
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
    lineHeight: 48,
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
    marginRight: 8,
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
  // 创建团队表单样式
  createTeamContainer: {
    flex: 1,
    width: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#f8fafc',
  },
  card: {
    width: '95%', // 增加宽度，留出边距
    maxWidth: 500, // 设置最大宽度
    backgroundColor: '#ffffff',
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  cardHeader: {
    padding: 24,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f5f9',
    alignItems: 'center',
  },
  cardTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1f2937',
    marginBottom: 8,
    textAlign: 'center',
  },
  cardDescription: {
    fontSize: 16,
    color: '#6b7280',
    textAlign: 'center',
  },
  cardContent: {
    padding: 24,
  },
  inputGroup: {
    marginBottom: 20,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#d1d5db',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    backgroundColor: '#ffffff',
  },
  textarea: {
    minHeight: 100,
    textAlignVertical: 'top',
  },
  submitButton: {
    backgroundColor: '#3b82f6',
    borderRadius: 8,
    padding: 16,
    alignItems: 'center',
  },
  submitButtonDisabled: {
    backgroundColor: '#9ca3af',
  },
  submitButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  // ScrollView 样式
  scrollView: {
    width: "100%"
  },
  // 标签页样式
  tabsContainer: {
    width: '100%',
    justifyContent: 'flex-start',
    alignItems: 'center',
    padding: 8,
    paddingTop: 40, // 增加顶部间距
    backgroundColor: '#f8fafc',
  },
  tabContent: {
    width: '100%',
  },
  tabButtons: {
    flexDirection: 'row',
    marginTop: 20,
    backgroundColor: '#f1f5f9',
    borderRadius: 8,
    padding: 4,
  },
  tabButton: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 6,
    alignItems: 'center',
  },
  tabButtonActive: {
    backgroundColor: '#ffffff',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  tabButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#6b7280',
  },
  tabButtonTextActive: {
    color: '#3b82f6',
  },
  // 搜索团队样式
  searchContainer: {
    flexDirection: 'row',
    gap: 8,
  },
  searchInput: {
    flex: 1,
  },
  searchButton: {
    backgroundColor: '#3b82f6',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    justifyContent: 'center',
    alignItems: 'center',
    minWidth: 80,
  },
  searchButtonDisabled: {
    backgroundColor: '#9ca3af',
  },
  searchButtonText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '600',
  },
  // 团队信息卡片样式
  teamInfoCard: {
    backgroundColor: '#f8fafc',
    borderRadius: 8,
    padding: 16,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#e5e7eb',
  },
  teamInfoTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1f2937',
    marginBottom: 12,
  },
  teamInfoItem: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  teamInfoLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
    width: 80,
  },
  teamInfoValue: {
    fontSize: 14,
    color: '#6b7280',
    flex: 1,
  },
});
export default HomeScreen;



