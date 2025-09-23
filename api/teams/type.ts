
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
    user_id: string;
    user_name: string;
    user_email: string;
    user_avatar: string;
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
  interface Checkin {
    id: string;
    user_id: string;
    image_url: string;
    location: string;
    user_name: string;
    user_email: string;
    user_avatar: string;
    created_at: number;
    status: 'on-time' | 'late' | 'absent';
  }

  interface HomeData {
    team: {
      id: string;
      name: string;
      address: string;
      user_id: string;
      created_at: string;
      updated_at: string;
      description: string;
    };
    statistics: {
      total_members: number;
      today_checkin_count: number;
      today_checkin_users: number;
      today_checkin_photos: string[];
    };
    today_checkins: Checkin[];
  }