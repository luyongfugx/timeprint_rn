
  interface TeamInfo {
    id: string;
    name: string;
    address: string | null;
    description: string | null;
    created_at: string;
    member_count: number;
    user_id?: string; // 从示例数据中看到的可选字段
    updated_at?: string; // 从示例数据中看到的可选字段
  }
  
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
    team_id?: string; // 从示例数据中看到的可选字段
    role?: string; // 从示例数据中看到的可选字段
  }
  
  interface TeamMembership {
    team_id: string;
    role: string;
    teams: TeamInfo;
  }
  
  interface CheckinRecord {
    id: string;
    memberName: string;
    avatar: string;
    time: string;
    location: string;
    photos: string[];
    status: 'on-time' | 'late' | 'absent';
  }