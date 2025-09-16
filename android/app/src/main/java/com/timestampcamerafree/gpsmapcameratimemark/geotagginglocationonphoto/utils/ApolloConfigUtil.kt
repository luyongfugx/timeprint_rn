package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils


import android.util.Log
import com.google.gson.Gson
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.AndroidConf
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.OfficialLogoConfig
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okio.ByteString
import org.json.JSONObject
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import java.util.Base64

object ApolloConfigUtil {
    val TAG = "ApolloConfigUtil"
    val androidConf ="androidconf.json"
    val officialLogoConf = "officialLogoConf.json"
    val application = "application"
    //appid=timeprint&env=PRO&cluster=default
    private val client = OkHttpClient()
    private val baseUrl: String ="https://conf.aiboot.cloud"
    private val appId: String="timeprint"
    private val cluster: String = "default"
    private val secret: String ="446eb21060c343689e30724da2214631"// 访问密钥，用于签名
    /**
     * 计算 HMAC-SHA1 签名并Base64编码
     */
    private fun hmacSha1Base64(data: String, key: String): String {
        val mac = Mac.getInstance("HmacSHA1")
        val secretKey = SecretKeySpec(key.toByteArray(Charsets.UTF_8), "HmacSHA1")
        mac.init(secretKey)
        val rawHmac = mac.doFinal(data.toByteArray(Charsets.UTF_8))
        return Base64.getEncoder().encodeToString(rawHmac)
    }

    /**
     * 构造签名字符串
     * @param timestamp 当前时间戳字符串（毫秒）
     * @param pathWithQuery 请求路径及查询参数，如 /configs/appId/env/cluster/namespace?releaseKey=xxx
     */
    private fun buildSignature(timestamp: String, pathWithQuery: String): String {
        val stringToSign = "$timestamp\n$pathWithQuery"
        return hmacSha1Base64(stringToSign, secret)
    }

    /**
     * 拉取 Apollo 配置，带签名认证
     * @param clientIp 客户端IP，可选
     * @return
     */
    fun fetchAndroidConf(): AndroidConf {
        var body = fetchConfig(androidConf)
        val json = JSONObject(body)
        val configurations = json.getJSONObject("configurations")
        return Gson().fromJson(configurations.get("content").toString(), AndroidConf::class.java)
    }

    fun fetchOfficialLogoConf():OfficialLogoConfig {
        var body =  fetchConfig(officialLogoConf)
        val json = JSONObject(body)
        val configurations = json.getJSONObject("configurations")
        return Gson().fromJson(configurations.get("content").toString(), OfficialLogoConfig::class.java)
    }

    private fun fetchConfig(
        namespace: String = "application",
        releaseKey: String? = null,
        clientIp: String? = null
    ): String {
        // 构造请求路径和查询参数
        val path = "/configs/$appId/$cluster/$namespace"
        val queryParams = mutableListOf<String>()
        if (!releaseKey.isNullOrBlank()) queryParams.add("releaseKey=$releaseKey")
        if (!clientIp.isNullOrBlank()) queryParams.add("ip=$clientIp")
        val query = if (queryParams.isNotEmpty()) queryParams.joinToString("&") else ""

        val url = if (query.isNotEmpty()) "$baseUrl$path?$query" else "$baseUrl$path"
        Log.d(TAG,"url:$url")
        // 当前时间戳（毫秒）
        val timestamp = System.currentTimeMillis().toString()

        // pathWithQuery 用于签名
        val pathWithQuery = if (query.isNotEmpty()) "$path?$query" else path

        // 计算签名
        val signature = buildSignature(timestamp, pathWithQuery)

        // 构造请求头
        val authorizationHeader = "Apollo $appId:$signature"

        val request = Request.Builder()
            .url(url)
            .get()
            .addHeader("Authorization", authorizationHeader)
            .addHeader("Timestamp", timestamp)
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("Apollo 请求失败: HTTP ${response.code}")
            }
            val body = response.body?.string() ?: throw Exception("响应体为空")
            Log.d(TAG,"android body: $body")
            return body
        }
    }
}
