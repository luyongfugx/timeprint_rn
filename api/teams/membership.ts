import { API_BASE_URL } from "./config";
export async function getMembership(session:any) {
  const accessToken = session?.access_token;
  if (!accessToken) throw new Error("Not logged in");
  const res = await fetch(API_BASE_URL+"/api/teams/membership", {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`, // 把 Supabase token 带上
    }
  });
   const data = await res.json();
  return data
}



export async function getTeamMembers(session:any) {
  const accessToken = session?.access_token;
  if (!accessToken) throw new Error("Not logged in");
  const res = await fetch(API_BASE_URL+"/api/mobile/members", {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`, // 把 Supabase token 带上
    }
  });
   const data = await res.json();

  return data
}