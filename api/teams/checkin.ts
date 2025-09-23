import { API_BASE_URL } from "./config";
export async function doCheckIn(session:any,checkinData:any) {
  const accessToken = session?.access_token;
  if (!accessToken) throw new Error("Not logged in");
  const res = await fetch(API_BASE_URL+"/api/mobile/checkin", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`, // 把 Supabase token 带上
    },
    body: JSON.stringify(checkinData),
  });
   const data = await res.json();

  return data
}

export async function getCheckIns(session:any) {
  const accessToken = session?.access_token;
  if (!accessToken) throw new Error("Not logged in");
  const res = await fetch(API_BASE_URL+"/api/mobile/getcheckins", {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`, // 把 Supabase token 带上
    }
  });
   const data = await res.json();
  return data
}



