import { API_BASE_URL } from "./config";
export async function getHomeData(session:any) {
  const accessToken = session?.access_token;
  if (!accessToken) throw new Error("Not logged in");
  const res = await fetch(API_BASE_URL+"/api/mobile/home", {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`, // 把 Supabase token 带上
    }
  });
   const data = await res.json();

  return data
}
