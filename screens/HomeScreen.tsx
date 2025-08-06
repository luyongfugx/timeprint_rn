
import React, { useState,useEffect } from 'react';
import {   View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  TouchableOpacity } from 'react-native';
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

const API_URL = 'https://api.example.com/checkin-records'; // Replace with your actual API endpoint


const todayPhotos = [
  'https://images.pexels.com/photos/3184360/pexels-photo-3184360.jpeg?w=150&h=150&fit=crop',
  'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?w=150&h=150&fit=crop',
  'https://images.pexels.com/photos/3184357/pexels-photo-3184357.jpeg?w=150&h=150&fit=crop',
  'https://images.pexels.com/photos/3184396/pexels-photo-3184396.jpeg?w=150&h=150&fit=crop',
];

const HomeScreen = ({ navigation }: { navigation: any }) => {
  const viewPhoto = (photoUrl: CheckinRecord) => {
    navigation.navigate('PhotoView', { photoUrl });
  };
  const [checkinRecords, setCheckinRecords] = useState<CheckinRecord[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
 const { t } = useTranslation();
  useEffect(() => {
    const fetchCheckinRecords = async () => {
      try {
        setLoading(true);
        const response = await fetch(API_URL);
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data: CheckinRecord[] = await response.json();
        setCheckinRecords(data);
      } catch (err: unknown) {
       // setError(err instanceof Error ? err.message : 'Failed to fetch check-in records');
        // Fallback to mock data if API fails (remove in production)
        setCheckinRecords([
          {
            id: '1',
            memberName: '张小',
            avatar: 'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?w=100&h=100&fit=crop&crop=face',
            time: '09:00',
            location: t('headquarters'),
            photos: [
              'https://images.pexels.com/photos/3184360/pexels-photo-3184360.jpeg?w=300&h=200&fit=crop',
              'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?w=300&h=200&fit=crop',
              'https://images.pexels.com/photos/3184357/pexels-photo-3184357.jpeg?w=300&h=200&fit=crop',
            ],
            status: 'on-time',
          },
          {
            id: '2',
            memberName: '李小红',
            avatar: 'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?w=100&h=100&fit=crop&crop=face',
            time: '09:15',
            location: '公司总部',
            photos: [
              'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?w=300&h=200&fit=crop',
              'https://images.pexels.com/photos/3184396/pexels-photo-3184396.jpeg?w=300&h=200&fit=crop',
            ],
            status: 'late',
          },
          {
            id: '3',
            memberName: '王大强',
            avatar: 'https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg?w=100&h=100&fit=crop&crop=face',
            time: '08:55',
            location: '公司总部',
            photos: [
              'https://images.pexels.com/photos/3184357/pexels-photo-3184357.jpeg?w=300&h=200&fit=crop',
            ],
            status: 'on-time',
          },
        ]);
      } finally {
        setLoading(false);
      }
    };

    fetchCheckinRecords();
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'on-time':
        return '#10b981';
      case 'late':
        return '#f59e0b';
      case 'absent':
        return '#ef4444';
      default:
        return '#6b7280';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'on-time':
        return t('on-time');
      case 'late':
        return t('late');
      case 'absent':
        return t('absent');
      default:
        return t('unknown');
    }
  };
    const gotoMember = () => {
      navigation.navigate('Member')
    };

  return (
    <SafeAreaView style={styles.container}>
  <ScrollView showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>{t('teamCheckin')}</Text>
          <Text style={styles.subtitle}>{t('todayIs')} {new Date().toLocaleDateString()}</Text>
        </View>

        {/* Stats Cards */}
        <View style={styles.statsContainer}>
          <View style={styles.statCard}>
            <TouchableOpacity onPress={gotoMember} >
            <View style={styles.statIconContainer}>
              <Users size={24} color="#3b82f6" />
            </View>
            <Text style={styles.statNumber}>28</Text>
            <Text style={styles.statLabel}>{t('teamMembers')}</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.statCard}>
            <View style={styles.statIconContainer}>
              <Clock size={24} color="#10b981" />
            </View>
            <Text style={styles.statNumber}>25</Text>
            <Text style={styles.statLabel}>{t('checkedIn')}</Text>
          </View>
          <View style={styles.statCard}>
            <View style={styles.statIconContainer}>
              <TrendingUp size={24} color="#f59e0b" />
            </View>
            <Text style={styles.statNumber}>89%</Text>
            <Text style={styles.statLabel}>{t('attendanceRate')}</Text>
          </View>
        </View>

        {/* Today's Photos */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Camera size={20} color="#374151" />
            <Text style={styles.sectionTitle}>{t('todaysPhotos')}</Text>
          </View>
          <ScrollView 
            horizontal 
            showsHorizontalScrollIndicator={false} 
            style={styles.photosScroll}
            contentContainerStyle={styles.todayPhotosContent}
          >
            {todayPhotos.map((photo, index) => (
              <TouchableOpacity key={index} style={styles.photoContainer}>
                <Image source={{ uri: photo }} style={styles.photo} />
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
            checkinRecords.map((record: CheckinRecord) => (
            <View key={record.id} style={styles.recordCard}>
              <View style={styles.recordHeader}>
                <View style={styles.memberInfo}>
                  <Image source={{ uri: record.avatar }} style={styles.memberAvatar} />
                  <View style={styles.memberDetails}>
                    <Text style={styles.memberName}>{record.memberName}</Text>
                    <View style={styles.timeLocationContainer}>
                      <Clock size={14} color="#6b7280" />
                      <Text style={styles.timeText}>{record.time}</Text>
                      <MapPin size={14} color="#6b7280" />
                      <Text style={styles.locationText}>{record.location}</Text>
                    </View>
                  </View>
                </View>
                <View style={[styles.statusBadge, { backgroundColor: getStatusColor(record.status) }]}>
                  <Text style={styles.statusText}>{getStatusText(record.status)}</Text>
                </View>
              </View>
              <ScrollView 
                horizontal 
                showsHorizontalScrollIndicator={false} 
                style={styles.photosContainer}
                contentContainerStyle={styles.photosContent}
              >
                {record.photos.map((photo: string, index: number) => (
                  <TouchableOpacity 
                    key={index} 
                    style={styles.photoWrapper}
                    onPress={() => viewPhoto(record)}
                  >
                    <Image source={{ uri: photo }} style={styles.checkinPhoto} />
                    {record.photos.length > 1 && (
                      <View style={styles.photoCounter}>
                        <Text style={styles.photoCounterText}>
                          {index + 1}/{record.photos.length}
                        </Text>
                      </View>
                    )}
                  </TouchableOpacity>
                ))}
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
    fontSize: 16,
    fontWeight: '600',
    color: '#1f2937',
    marginBottom: 4,
  },
  timeLocationContainer: {
    flexDirection: 'row',
    alignItems: 'center',
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
});
export default HomeScreen;


