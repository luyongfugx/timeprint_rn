import { API_BASE_URL } from "./config";
export async function getMembership(session:any) {
  const accessToken = session?.access_token;
  if (!accessToken) throw new Error("Not logged in");
  console.log("accessToken:"+accessToken)
  const res = await fetch(API_BASE_URL+"/api/teams/membership", {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`, // 把 Supabase token 带上
    }
  });
  console.log("API_BASE_URL:"+API_BASE_URL+"/api/teams/membership")
   const data = await res.json();
   console.log("data:"+data)

  return data
}
