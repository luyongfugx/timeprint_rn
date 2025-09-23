import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  Image,
  TouchableOpacity,
  NativeModules,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Search, MapPin, Clock, Phone, Mail, MoveVertical as MoreVertical } from 'lucide-react-native';
import { getTeamMembers } from '../api/teams/membership';

const { AuthBridge } = NativeModules;

export default function MembersManagement({ navigation }: { navigation: any })  {
  const [loading, setLoading] = useState<boolean>(true);
  const { t } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
   const [filteredMembers, setFilteredMembers] = useState<TeamMember[]>([]);
  const [teamMembers, setTeamMembers] = useState<TeamMember[]>([]);
  const handleSearch = (query: string) => {
    setSearchQuery(query);
    const filtered = teamMembers.filter(
      (member) =>
        member.user_name.toLowerCase().includes(query.toLowerCase()) ||
        member.user_email.toLowerCase().includes(query.toLowerCase()) 
    );
    setFilteredMembers(filtered);
  };

    useEffect(() => {
      const checkAuthState = async () => {
        const sessionString = await AuthBridge.getSession();
        if (sessionString) {
            const session = JSON.parse(sessionString);
            setLoading(true);
            const members= await getTeamMembers(session)
            if(members){
              setTeamMembers(members);
              setFilteredMembers(members);
            }
            setLoading(false);
        }
      };
       checkAuthState();
    }, []);
    const goToUser = (userId: String) => {
      navigation.navigate('UserInfo', { userId });
    };
  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>{t('membersManagement')}</Text>
        <Text style={styles.subtitle}>{t('totalMembers', { count: filteredMembers.length })}</Text>
      </View>

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <View style={styles.searchInputContainer}>
          <Search size={20} color="#9ca3af" />
          <TextInput
            style={styles.searchInput}
            placeholder={t('searchMembers')}
            value={searchQuery}
            onChangeText={handleSearch}
            placeholderTextColor="#9ca3af"
          />
        </View>
      </View>
      <View style={styles.searchContainer}>   
             {loading && (
                  <Text>{t('loading')}</Text>
               )}
      </View>
      {/* Members List */}
      <ScrollView style={styles.membersList} showsVerticalScrollIndicator={false}>
        {filteredMembers.map((member) => (
          <TouchableOpacity key={member.id} style={styles.memberCard} onPress={() => goToUser(member.user_id)} >
            <View style={styles.memberHeader}>
              <View style={styles.avatarContainer}>
                <Image source={{ uri: member.user_avatar }} style={styles.avatar} />
              </View>
              <View style={styles.memberMainInfo}>
                <Text style={styles.memberName}>{member.user_name}</Text>
              </View>
              <TouchableOpacity style={styles.moreButton}>
                <MoreVertical size={20} color="#9ca3af" />
              </TouchableOpacity>
            </View>

            <View style={styles.memberDetails}>
              <View style={styles.contactInfo}>
                <View style={styles.contactItem}>
                  <Mail size={14} color="#6b7280" />
                  <Text style={styles.contactText}>{member.user_email}</Text>
                </View>
              </View>

              {/* <View style={styles.checkinInfo}>
                <View style={styles.checkinItem}>
                  <Clock size={14} color="#6b7280" />
                  <Text style={styles.checkinText}>{t('lastCheckin')}: {member.lastCheckinTime}</Text>
                </View>
                <View style={styles.checkinItem}>
                  <MapPin size={14} color="#6b7280" />
                  <Text style={styles.checkinText}>{member.lastLocation}</Text>
                </View>
              </View> */}
{/* 
              <View style={styles.statusContainer}>
                <View
                  style={[
                    styles.statusBadge,
                    { backgroundColor: getStatusColor(member.status) + '20' },
                  ]}
                >
                  <View
                    style={[
                      styles.statusDot,
                      { backgroundColor: getStatusColor(member.status) },
                    ]}
                  />
                  <Text
                    style={[
                      styles.statusLabel,
                      { color: getStatusColor(member.status) },
                    ]}
                  >
                    {getStatusText(member.status)}
                  </Text>
                </View>
              </View> */}
            </View>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
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
  searchContainer: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  searchInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#ffffff',
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 12,
    gap: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 1,
  },
  searchInput: {
    flex: 1,
    fontSize: 16,
    color: '#1f2937',
  },
  membersList: {
    flex: 1,
    paddingHorizontal: 20,
  },
  memberCard: {
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
  memberHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  avatarContainer: {
    position: 'relative',
    marginRight: 12,
  },
  avatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
  },
  statusIndicator: {
    position: 'absolute',
    bottom: 2,
    right: 2,
    width: 14,
    height: 14,
    borderRadius: 7,
    borderWidth: 2,
    borderColor: '#ffffff',
  },
  memberMainInfo: {
    flex: 1,
  },
  memberName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1f2937',
    marginBottom: 2,
  },
  memberPosition: {
    fontSize: 14,
    color: '#3b82f6',
    marginBottom: 2,
  },
  memberDepartment: {
    fontSize: 12,
    color: '#6b7280',
  },
  moreButton: {
    padding: 4,
  },
  memberDetails: {
    gap: 8,
  },
  contactInfo: {
    gap: 6,
  },
  contactItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  contactText: {
    fontSize: 14,
    color: '#6b7280',
  },
  checkinInfo: {
    gap: 6,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#f3f4f6',
  },
  checkinItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  checkinText: {
    fontSize: 14,
    color: '#6b7280',
  },
  statusContainer: {
    paddingTop: 8,
    alignItems: 'flex-start',
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
    gap: 6,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  statusLabel: {
    fontSize: 12,
    fontWeight: '600',
  },
});