import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  Image,
  TouchableOpacity,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Search, MapPin, Clock, Phone, Mail, MoveVertical as MoreVertical } from 'lucide-react-native';

interface TeamMember {
  id: string;
  name: string;
  avatar: string;
  position: string;
  department: string;
  phone: string;
  email: string;
  lastCheckinTime: string;
  lastLocation: string;
  status: 'online' | 'offline' | 'away';
}

const mockMembers: TeamMember[] = [
  {
    id: '1',
    name: '张小明',
    avatar: 'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?w=100&h=100&fit=crop&crop=face',
    position: '前端开发工程师',
    department: '技术部',
    phone: '138****5678',
    email: 'zhang@company.com',
    lastCheckinTime: '09:00',
    lastLocation: '公司总部',
    status: 'online',
  },
  {
    id: '2',
    name: '李小红',
    avatar: 'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?w=100&h=100&fit=crop&crop=face',
    position: 'UI/UX设计师',
    department: '设计部',
    phone: '139****1234',
    email: 'li@company.com',
    lastCheckinTime: '09:15',
    lastLocation: '公司总部',
    status: 'online',
  },
  {
    id: '3',
    name: '王大强',
    avatar: 'https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg?w=100&h=100&fit=crop&crop=face',
    position: '后端开发工程师',
    department: '技术部',
    phone: '137****9876',
    email: 'wang@company.com',
    lastCheckinTime: '08:55',
    lastLocation: '公司总部',
    status: 'online',
  },
  {
    id: '4',
    name: '陈小丽',
    avatar: 'https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?w=100&h=100&fit=crop&crop=face',
    position: '产品经理',
    department: '产品部',
    phone: '136****4567',
    email: 'chen@company.com',
    lastCheckinTime: '09:30',
    lastLocation: '分公司',
    status: 'away',
  },
  {
    id: '5',
    name: '刘小军',
    avatar: 'https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?w=100&h=100&fit=crop&crop=face',
    position: '测试工程师',
    department: '技术部',
    phone: '135****7890',
    email: 'liu@company.com',
    lastCheckinTime: '昨天 18:00',
    lastLocation: '公司总部',
    status: 'offline',
  },
];

export default function MembersManagement() {
  const [searchQuery, setSearchQuery] = useState('');
  const [filteredMembers, setFilteredMembers] = useState(mockMembers);

  const handleSearch = (query: string) => {
    setSearchQuery(query);
    const filtered = mockMembers.filter(
      (member) =>
        member.name.toLowerCase().includes(query.toLowerCase()) ||
        member.position.toLowerCase().includes(query.toLowerCase()) ||
        member.department.toLowerCase().includes(query.toLowerCase())
    );
    setFilteredMembers(filtered);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online':
        return '#10b981';
      case 'away':
        return '#f59e0b';
      case 'offline':
        return '#6b7280';
      default:
        return '#6b7280';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'online':
        return '在线';
      case 'away':
        return '离开';
      case 'offline':
        return '离线';
      default:
        return '未知';
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>成员管理</Text>
        <Text style={styles.subtitle}>总共 {mockMembers.length} 名成员</Text>
      </View>

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <View style={styles.searchInputContainer}>
          <Search size={20} color="#9ca3af" />
          <TextInput
            style={styles.searchInput}
            placeholder="搜索成员姓名、职位或部门"
            value={searchQuery}
            onChangeText={handleSearch}
            placeholderTextColor="#9ca3af"
          />
        </View>
      </View>

      {/* Members List */}
      <ScrollView style={styles.membersList} showsVerticalScrollIndicator={false}>
        {filteredMembers.map((member) => (
          <TouchableOpacity key={member.id} style={styles.memberCard}>
            <View style={styles.memberHeader}>
              <View style={styles.avatarContainer}>
                <Image source={{ uri: member.avatar }} style={styles.avatar} />
                <View
                  style={[
                    styles.statusIndicator,
                    { backgroundColor: getStatusColor(member.status) },
                  ]}
                />
              </View>
              <View style={styles.memberMainInfo}>
                <Text style={styles.memberName}>{member.name}</Text>
                <Text style={styles.memberPosition}>{member.position}</Text>
                <Text style={styles.memberDepartment}>{member.department}</Text>
              </View>
              <TouchableOpacity style={styles.moreButton}>
                <MoreVertical size={20} color="#9ca3af" />
              </TouchableOpacity>
            </View>

            <View style={styles.memberDetails}>
              <View style={styles.contactInfo}>
                <View style={styles.contactItem}>
                  <Phone size={14} color="#6b7280" />
                  <Text style={styles.contactText}>{member.phone}</Text>
                </View>
                <View style={styles.contactItem}>
                  <Mail size={14} color="#6b7280" />
                  <Text style={styles.contactText}>{member.email}</Text>
                </View>
              </View>

              <View style={styles.checkinInfo}>
                <View style={styles.checkinItem}>
                  <Clock size={14} color="#6b7280" />
                  <Text style={styles.checkinText}>上次打卡: {member.lastCheckinTime}</Text>
                </View>
                <View style={styles.checkinItem}>
                  <MapPin size={14} color="#6b7280" />
                  <Text style={styles.checkinText}>{member.lastLocation}</Text>
                </View>
              </View>

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
              </View>
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