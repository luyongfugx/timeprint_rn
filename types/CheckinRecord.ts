interface CheckinRecord {
    id: string;
    memberName: string;
    avatar: string;
    time: string;
    location: string;
    photos: string[];
    status: 'on-time' | 'late' | 'absent';
  }