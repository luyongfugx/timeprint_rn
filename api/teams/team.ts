import { API_BASE_URL } from "./config";
export async function getTeamInfoById(session:any,id:String) {
    const accessToken = session?.access_token;
    if (!accessToken) throw new Error("Not logged in");
    const res = await fetch(`${API_BASE_URL}/api/mobile/teams/${id}`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${accessToken}`, // 把 Supabase token 带上
      }
    });
     const data = await res.json();
    return data
  }

  export async function joinTeam(session:any,id:String) {
    const accessToken = session?.access_token;
    if (!accessToken) throw new Error("Not logged in");
    const res = await fetch(`${API_BASE_URL}/api/mobile/teams/join/${id}`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${accessToken}`, // 把 Supabase token 带上
      }
    });
     const data = await res.json();
    return data
  }

  export async function createTeam(session:any,team:any) {
    const accessToken = session?.access_token;
    if (!accessToken) throw new Error("Not logged in");
    const res = await fetch(API_BASE_URL+"/api/mobile/teams", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`, // 把 Supabase token 带上
      },
      body: JSON.stringify(team),
    });
     const data = await res.json();

    return data
  }
  