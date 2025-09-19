package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils


import android.content.Context
import android.net.Uri
import android.util.Log
import com.tencent.cos.xml.CosXmlService
import com.tencent.cos.xml.exception.CosXmlClientException
import com.tencent.cos.xml.exception.CosXmlServiceException
import com.tencent.cos.xml.listener.CosXmlResultListener
import com.tencent.cos.xml.model.CosXmlRequest
import com.tencent.cos.xml.model.CosXmlResult
import com.tencent.cos.xml.model.`object`.PutObjectRequest
import com.tencent.cos.xml.transfer.COSXMLUploadTask.COSXMLUploadTaskResult
import com.tencent.cos.xml.transfer.TransferConfig
import com.tencent.cos.xml.transfer.TransferManager
import com.tencent.qcloud.core.auth.QCloudCredentialProvider
import com.tencent.qcloud.core.auth.ShortTimeCredentialProvider
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.Config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.ServiceConfig
import io.reactivex.rxjava3.internal.operators.single.SingleDoOnSuccess
import java.io.ByteArrayInputStream
import java.io.InputStream
import java.nio.charset.StandardCharsets
import java.util.Date
import java.util.Locale


/**
 * 腾讯云存储
 *
 */
object TencentCOSUtils {

    private const val TAG = "TencentCOSUtils"

    // 替换为你的 AppId、Region 和 Bucket
    private const val REGION = "ap-singapore" // 例如: ap-beijing
    private const val BUCKET = "timeprintandroid-1330977225"


    private const val TEAM_BUCKET = "timeprint-team-1330977225"

    private var cosXmlService: CosXmlService? = null
    private var transferManager: TransferManager? = null

    fun init(context: Context) {
        if (cosXmlService == null) {
            // 初始化 CosXmlServiceConfig
            val serviceConfig = com.tencent.cos.xml.CosXmlServiceConfig.Builder()
                .setRegion(REGION)
                .isHttps(true) // 建议使用 HTTPS
                .builder()
            var  secretId = "AKIDbP0PwMcVFnESUJuISUM4ZrwqY6UhhZFi"; //用户的 SecretId，建议使用子账号密钥，授权遵循最小权限指引，降低使用风险。子账号密钥获取可参见 https://cloud.tencent.com/document/product/598/37140
            var secretKey = "K0VotlQs79yazBA1rUeeR1NYWGn7E6nH"; //用户的 SecretKey，建议使用子账号密钥，授权遵循最小权限指引，降低使用风险。子账号密钥获取可参见 https://cloud.tencent.com/document/product/598/371
            // keyDuration 为请求中的密钥有效期，单位为秒
            var  myCredentialProvider: QCloudCredentialProvider =
                ShortTimeCredentialProvider(secretId, secretKey, 300);
            cosXmlService = CosXmlService(
                context,
                serviceConfig, myCredentialProvider
            )
        }

        if (transferManager == null && cosXmlService != null) {
            // 初始化 TransferConfig
            val transferConfig = TransferConfig.Builder()
                .setDivisionForUpload(2097152)
                // 设置分块上传时的分块大小 默认为1M
                .setSliceSizeForUpload(1048576)
                // 设置是否强制使用简单上传, 禁止分块上传
                .setForceSimpleUpload(false)
                .build();

            // 初始化 TransferManager
            transferManager = TransferManager(cosXmlService, transferConfig)
        }
    }

    /**
     * 上传本地文件
     *
     * @param context  Context
     * @param localFilePath 本地文件路径
     * @param cosPath      COS 上的路径，例如："path/to/your/file.jpg"
     * @param progressListener 上传进度监听器 (可选)
     * @param resultListener   上传结果监听器
     */


    fun uploadTeamFile(
        context: Context,
        uri: Uri,
        cosPath: String,
        onSuccess: (accessUrl: String?) -> Unit
    ) {
        ensureInitialized(context)
        Log.d(TAG, "uploadFile: putRequest: BUCKET: $TEAM_BUCKET  cosPath $cosPath  uri: ${uri}")
        val putRequest = PutObjectRequest(TEAM_BUCKET, cosPath,uri)

        var cosxmlUploadTask = transferManager?.upload(putRequest, "")
        cosxmlUploadTask!!.setCosXmlResultListener(object : CosXmlResultListener {
            override fun onSuccess(request: CosXmlRequest, result: CosXmlResult) {
                val uploadResult =
                    result as COSXMLUploadTaskResult
                val accessUrl = uploadResult.accessUrl
                Log.d(TAG, "uploadFile: onSuccess: $accessUrl")
                onSuccess(accessUrl)
            }

            // 如果您使用 kotlin 语言来调用，请注意回调方法中的异常是可空的，否则不会回调 onFail 方法，即：
            // clientException 的类型为 CosXmlClientException?，serviceException 的类型为 CosXmlServiceException?
            override fun onFail(
                request: CosXmlRequest,
                clientException: CosXmlClientException?,
                serviceException: CosXmlServiceException?
            ) {
                if (clientException != null) {
                    Log.d(TAG, "uploadFile: clientException: ${clientException.toString()}")
                    clientException.printStackTrace()
                } else {
                    serviceException!!.printStackTrace()
                    Log.d(TAG, "uploadFile: serviceException: ${serviceException.toString()}")
                }
                onSuccess(null)
            }
        })
    }

    fun uploadFile(
        context: Context,
        uri: Uri,
        cosPath: String,
    ) {
        ensureInitialized(context)
        Log.d(TAG, "uploadFile: putRequest: BUCKET: $BUCKET  cosPath $cosPath  uri: ${uri}")
        val putRequest = PutObjectRequest(BUCKET, cosPath,uri)

         var cosxmlUploadTask = transferManager?.upload(putRequest, "")
        cosxmlUploadTask!!.setCosXmlResultListener(object : CosXmlResultListener {
            override fun onSuccess(request: CosXmlRequest, result: CosXmlResult) {
                val uploadResult =
                    result as COSXMLUploadTaskResult
                Log.d(TAG, "uploadFile: onSuccess: ${uploadResult.accessUrl}")
            }

            // 如果您使用 kotlin 语言来调用，请注意回调方法中的异常是可空的，否则不会回调 onFail 方法，即：
            // clientException 的类型为 CosXmlClientException?，serviceException 的类型为 CosXmlServiceException?
            override fun onFail(
                request: CosXmlRequest,
               clientException: CosXmlClientException?,
                serviceException: CosXmlServiceException?
            ) {

                if (clientException != null) {
                    Log.d(TAG, "uploadFile: clientException: ${clientException.toString()}")
                    clientException.printStackTrace()
                } else {
                    serviceException!!.printStackTrace()
                    Log.d(TAG, "uploadFile: serviceException: ${serviceException.toString()}")
                }
            }
        })


    }

    private fun stringToInputStream(text: String): InputStream {
        val byteArray = text.toByteArray(StandardCharsets.UTF_8) // 推荐使用 UTF-8 编码
        return ByteArrayInputStream(byteArray)
    }

    /**
     * 上传错误
     *
     * @param context
     * @param useId
     * @param text
     */
    fun uploadErrorLog(
        context: Context,
        text: String,
        fileName:String
    ){
        val timeSlice = GpDateFormat.getNowTimeSlice()
        val useId = Config.newInstance(App.context).getAppUserId()
        val year = timeSlice[0]
        val month = timeSlice[1]
        val day = timeSlice[2]
        val time = Date().time
        val deviceId= GPAppUtils.getDeviceInfoString()
        //获取gasessionId
        val gaSessionId = AnalyticsManager.getGaSessionId()
        //国家码使用地理位置里的
        val lastLocation =  ServiceConfig.getLocationService().getLocationInfo()
        var countryCode =   if (lastLocation!=null) { lastLocation.countryCode} else {  Locale.getDefault().country.uppercase()}
        if (countryCode.isNullOrEmpty() ){
            countryCode = Locale.getDefault().country.uppercase()
        }
        val versionName = App.context.packageManager.getPackageInfo(App.context.packageName, 0).versionName
        val  cosPath = "log/${countryCode}/${year}/${month}/${day}/${versionName}_${deviceId}_${fileName}_${gaSessionId}_${useId}_${time}.txt"
        uploadFileByInputStream(
            context,
            cosPath,
            stringToInputStream(text)
        )
    }

    fun uploadFileByInputStream(
        context: Context,
        cosPath: String,
        inputStream: InputStream
    ) {
        ensureInitialized(context)

//        val putRequest = PutObjectRequest(BUCKET, cosPath, localFilePath)
        Log.d(TAG, "uploadFile: putRequest: BUCKET: $BUCKET  cosPath $cosPath")
        val putRequest = PutObjectRequest(BUCKET, cosPath,inputStream)

        var cosxmlUploadTask = transferManager?.upload(putRequest, "")
        cosxmlUploadTask!!.setCosXmlResultListener(object : CosXmlResultListener {
            override fun onSuccess(request: CosXmlRequest, result: CosXmlResult) {
                val uploadResult =
                    result as COSXMLUploadTaskResult
                Log.d(TAG, "uploadFile: onSuccess: ${uploadResult.accessUrl}")
            }

            // 如果您使用 kotlin 语言来调用，请注意回调方法中的异常是可空的，否则不会回调 onFail 方法，即：
            // clientException 的类型为 CosXmlClientException?，serviceException 的类型为 CosXmlServiceException?
            override fun onFail(
                request: CosXmlRequest,
                clientException: CosXmlClientException?,
                serviceException: CosXmlServiceException?
            ) {

                if (clientException != null) {
                    Log.d(TAG, "uploadFile: clientException: $clientException")
                    clientException.printStackTrace()
                } else {
                    serviceException!!.printStackTrace()
                    Log.d(TAG, "uploadFile: serviceException: $serviceException")
                }
            }
        })


    }

    private fun ensureInitialized(context: Context) {
        if (cosXmlService == null || transferManager == null) {
            init(context.applicationContext) // Use application context to avoid memory leaks
        }
    }

}