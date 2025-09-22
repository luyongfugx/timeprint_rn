package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import android.annotation.SuppressLint
import android.util.Log
import com.google.android.gms.maps.model.LatLng
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.GPRealTimeModel
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import com.google.gson.Gson
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.WeatherInfoResponse
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.weather.IGpWeatherService
import org.jose4j.jws.AlgorithmIdentifiers
import org.jose4j.jws.JsonWebSignature
import org.jose4j.jwt.JwtClaims
import org.jose4j.jwt.NumericDate
import org.json.JSONObject

import java.io.IOException
import java.security.KeyFactory
import java.security.PrivateKey
import java.security.spec.PKCS8EncodedKeySpec
import java.util.Base64

object GpHttpRequestApi {
    //接口时间
    private val TAG = "GpHttpRequestApi"
    private const val TIME_API_URL:String = "https://timeprint.aiboot.cloud/api/mask/timezone"
    //团队接口
    private const val GROUP_BASE_API_URL:String = "http://localhost:3000"
    private const val SUPABASE_URL = "https://jagoxfrvvxfnpdjvbtrf.supabase.co"
    private const val SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphZ294ZnJ2dnhmbnBkanZidHJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU5MzM5NDUsImV4cCI6MjA3MTUwOTk0NX0.P1wI24InDGhCHYltNSWUXQshp-OcM38WUGGCg02Pa3Q";

    fun realtime(lat:Double,lon:Double ,callback: (GPRealTimeModel?) -> Unit) {


        var json = """
            {
                "lat": ${lat},
                "lon": ${lon}
            }
        """.trimIndent()
        //越南 lat:14.5242755 lon:109.0343893
//         json = """
//            {
//                "lat": 14.5242755,
//                "lon": 109.0343893
//            }
//        """.trimIndent()

       // -0.8769138 lon:14.8162353
       // latLng = LatLng(19.969528, 58.663483)
//        json = """
//            {
//                "lat": 19.969528,
//                "lon": 58.663483
//            }
//        """.trimIndent()
        val requestBody = json.toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url(TIME_API_URL) // 替换为你的服务器 URL
            .post(requestBody)
            .build()
        val client = OkHttpClient()
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e(TAG, "Request failed: ${e.message}")
                callback(GPRealTimeModel(status = 500, msg = e.message))
            }
            @SuppressLint("SuspiciousIndentation")
            override fun onResponse(call: Call, response: Response) {
                val responseBody = response.body?.string()
                if (response.isSuccessful && responseBody != null) {
                    try {
                        Log.d(TAG, "gpRealTimeModel Server ${responseBody}")
                        var bodyText =
                            "{\"msg\":\"ok\",\"status\":200,\"data\":{\"time\":\"2025-05-10 16:14:16\",\"timeZone\":\"GMT+1\"}}}"
                       // var bodyText =  {"msg":"ok","status":200,"data":{"time":"2025-05-10 17:44:42","timeZone":"GMT+1"}}
                        //  bodyText =  responseBody
                        val gpRealTimeModel =  Gson().fromJson(responseBody, GPRealTimeModel::class.java)
                            //设置
//                            gpRealTimeModel.data?.time = "2025-05-10 17:44:42"
//                           gpRealTimeModel.data?.timeZone = "GMT+1"
                            gpRealTimeModel.initTimeStamps()
                            gpRealTimeModel.status =200

                            callback(gpRealTimeModel)
                        val text ="realtime http  succ: lat:${lat} lon:${lon} res.body:${responseBody}}  gpRealTimeModel:${gpRealTimeModel}"
                        Log.d(TAG, "realtime httpx  succ: fromJson error ${text}")
                        TencentCOSUtils.uploadErrorLog(App.context,text,"realtime_succ")
                        // 在这里处理 gpRealTimeModel
                    } catch (e: Exception) {
                        val text ="realtime json error: lat:${lat} lon:${lon} res.body:${responseBody} error:${e.toString()}"
                        TencentCOSUtils.uploadErrorLog(App.context,text,"realtime_error")
                        callback(GPRealTimeModel(status = 500, msg = e.toString()))
                        Log.d(TAG, "fromJson error ${e.toString()}")
                    }
                } else {
                    val text ="realtime http  error: lat:${lat} lon:${lon} res.body:${responseBody}}"
                    TencentCOSUtils.uploadErrorLog(App.context,text,"realtime_error")
                    callback(GPRealTimeModel(status = 500, msg = response.message))
                    Log.e(TAG, "Response failed: ${response.code} ${response.message}")
                }
            }
        })
    }
    //feed back 地址
    private const val FEEDBACK_API_URL:String = "https://www.aigf.art/api/feedback/new"

    fun feedback(title:String,user:String,version:String,content:String,callback: (Int?) -> Unit) {
//        title: "test", content: "ere", user: "user"
        val json = """
            {
                "title": "${title}",
                "user": "${user}",
                "version": "android_${version}",
                "content": "${content}"
            }
        """.trimIndent()

        val requestBody = json.toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url(FEEDBACK_API_URL) // 替换为你的服务器 URL
            .header("Content-Type", "application/json")
            .header("Accept", "application/json")
            .post(requestBody)
            .build()
        val client = OkHttpClient()
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e(TAG, "onResponse failed: ${e.message}")
                callback(500)
            }
            @SuppressLint("SuspiciousIndentation")
            override fun onResponse(call: Call, response: Response) {
                val responseBody = response.body?.string()
                if (response.isSuccessful && responseBody != null) {
                    try {
                            callback(200)
                        // 在这里处理 gpRealTimeModel
                    } catch (e: Exception) {
                        callback(500)
                        Log.d(TAG, "fromJson error ${e.toString()}")
                    }
                } else {
                    callback(500)
                    Log.e(TAG, "Response failed: ${response.code} ${response.message}")
                }
            }
        })
    }

    //天气接口
    private val teamId = "TCY72Z837H"
    private val serviceId = "com.waynelu.weatherkit"
    private val keyId ="SGL63M688Y"
    private val privateKeyString ="MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg/MrsJpGEHRWa543l\n" +
            "QTPznwwLZRTkqLcFpS2bLbrjP3GgCgYIKoZIzj0DAQehRANCAATFMBahz/y9X4ea\n" +
            "CDnvd3tdCkUk7IzPJct7GdZF+h/r8i7hECDrhFiXevZvbTZl7NpJzItf3bzmSP2D\n" +
            "iSt4FjhT"
    //https://weatherkit.apple.com/api/v1/weather/{language}/{latitude}/{longitude}
   // private val appleWeatherApi = "https://weatherkit.apple.com/api/v1/weather"
    //代理
    private const val appleWeatherApi = "https://www.aigf.art/api/mask/weather"
    fun getWeather(latitude: Double, longitude: Double,language: String, dataSet:String,callback: IGpWeatherService.Callback) {
        var jwt =generateJWT()
//        temperatureUnit=celsius：返回摄氏度（°C）。
//        temperatureUnit=fahrenheit
        val  url = "${appleWeatherApi}/${language}/${latitude}/${longitude}?dataSets=$dataSet"
        val client = OkHttpClient()
        val request = Request.Builder()
            .url(url)
            .header("Authorization", "Bearer $jwt")
            .header("Content-Type", "application/json")
            .header("Accept", "application/json")
            .build()
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e(TAG, "onFailure Request failed: ${e.message}")
                callback.onError(e)
            }
            override fun onResponse(call: Call, response: Response) {
                //Log.d(TAG, "responseBody: $response")
                val responseBody = response.body?.string()
                if (response.isSuccessful && responseBody != null) {
                    try {
                        //Log.d(TAG, "responseBody: $responseBody")
                        val weatherInfoResponse  = Gson().fromJson(responseBody, WeatherInfoResponse::class.java)
                        val weatherInfo = weatherInfoResponse.data
                        callback.onCurrentWeather(weatherInfo)
                        // 在这里处理 gpRealTimeModel
                    } catch (e: Exception) {
                        callback.onError(e)
                    }
                } else {
                    callback.onError(Exception("Response failed: ${response.code} ${response.message} "))
                }
            }
        })
    }
    private fun generateJWT(): String {
//        .withIssuedAt(Date.from(now))
//            .withExpiresAt(Date.from(now.plusSeconds(3600)))

        val claims = JwtClaims()
        var now = NumericDate.now()
        //add 3600
        var expire  = NumericDate.now()
        expire.addSeconds(120)
        claims.issuer = teamId
        claims.issuedAt = now
        claims.expirationTime = expire
        claims.subject = serviceId
        val jws = JsonWebSignature()
        val id ="${teamId}.${serviceId}"
        jws.payload = claims.toJson()
        jws.keyIdHeaderValue = keyId
        jws.algorithmHeaderValue = AlgorithmIdentifiers.ECDSA_USING_P256_CURVE_AND_SHA256
        jws.keyIdHeaderValue= id
        val privateKey = getPrivateKey(privateKeyString)
        jws.key = privateKey
        return jws.getCompactSerialization()
    }

    private fun getPrivateKey(privateKeyString: String): PrivateKey {
        val deKey = privateKeyString.replace("-----BEGIN PRIVATE KEY-----\n", "").
        replace("-----END PRIVATE KEY-----\n", "").
        replace("\n", "").replace("\r", "")
        val keyBytes = Base64.getDecoder().decode(deKey)
        val keySpec = PKCS8EncodedKeySpec(keyBytes)
        val keyFactory = KeyFactory.getInstance("EC")
        return keyFactory.generatePrivate(keySpec)
    }

    //

    fun refreshSession(refreshToken: String, callback: (String?) -> Unit) {
        val client = OkHttpClient()
        val requestBody = FormBody.Builder()
            .add("refresh_token", refreshToken)
            .build()

        val request = Request.Builder()
            .url("$SUPABASE_URL/auth/v1/token?grant_type=refresh_token")
            .post(requestBody)
            .addHeader("apikey", SUPABASE_ANON_KEY)
            .addHeader("Content-Type", "application/x-www-form-urlencoded")
            .build()

//        client.newCall(request).execute().use { response ->
//            if (!response.isSuccessful){
//                callback("error")
//            }
//            val body = response.body?.string()
//            callback(body)
//
//        }
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e(TAG, "refreshSession request failed: ${e.message}")
                callback("error")
            }
            override fun onResponse(call: Call, response: Response) {
                val responseBody = response.body?.string()
                if (response.isSuccessful && responseBody != null) {
                    try {
                        Log.d(TAG, "refreshSession response data: $responseBody")
                        callback(responseBody)
                    } catch (e: Exception) {
                        Log.e(TAG, "refreshSession JSON parsing error: ${e.message}")
                        callback("error")
                    }
                } else {
                    Log.e(TAG, "refreshSession response failed: ${response.code} ${response.message}")
                    callback("error")
                }
            }
        })
    }

    fun checkIn(sessionJson: String,data:String, callback: (String?) -> Unit) {
        try {
            // 解析 JSON 字符串获取 session 对象
            val session = Gson().fromJson(sessionJson, Map::class.java)
            val accessToken = session["access_token"] as? String
            
            if (accessToken.isNullOrEmpty()) {
                Log.e(TAG, "Not logged in: access token is null or empty")
                callback(null)
                return
            }
            
            Log.d(TAG, "accessToken: $accessToken")
            
            val url = "$GROUP_BASE_API_URL/api/mobile/checkin"
            Log.d(TAG, "API_BASE_URL: $url")
            
            val client = OkHttpClient()
            val requestBody = data.toRequestBody("application/json".toMediaType())
            val request = Request.Builder()
                .url(url)
                .header("Authorization", "Bearer $accessToken")
                .header("Content-Type", "application/json")
                .header("Accept", "application/json")
                .post(requestBody)
                .build()
                
            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e(TAG, "getMembership request failed: ${e.message}")
                    callback(null)
                }
                
                override fun onResponse(call: Call, response: Response) {
                    val responseBody = response.body?.string()
                    if (response.isSuccessful && responseBody != null) {
                        try {
                            Log.d(TAG, "getMembership response data: $responseBody")
                          //  val data = Gson().fromJson(responseBody, Any::class.java)
                            callback(responseBody)
                        } catch (e: Exception) {
                            Log.e(TAG, "getMembership JSON parsing error: ${e.message}")
                            callback(null)
                        }
                    } else {
                        Log.e(TAG, "getMembership response failed: ${response.code} ${response.message}")
                        callback(null)
                    }
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "getMembership error: ${e.message}")
            callback(null)
        }
    }
    
}