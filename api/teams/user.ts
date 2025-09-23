import { API_BASE_URL } from "./config";
export async function getUserInfo(session:any,user_id:String) {
  const accessToken = session?.access_token;
  if (!accessToken) throw new Error("Not logged in");
  const res = await fetch(`${API_BASE_URL}/api/mobile/user?user_id=${user_id}`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`, // 把 Supabase token 带上
    }
  });
   const data = await res.json();

  return data
}