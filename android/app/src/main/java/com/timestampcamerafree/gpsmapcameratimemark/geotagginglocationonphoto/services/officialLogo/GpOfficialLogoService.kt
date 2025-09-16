package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.officialLogo

import android.content.Context
import android.util.Log
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.OfficialLogoConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.ApolloConfigUtil
import java.util.concurrent.Executors

/**
 * 获取官方logo
 *
 */
class GpOfficialLogoService: IGpOfficialLogoService {
    private val TAG = "GpOfficialLogoService"
    private val singleExecutor = Executors.newSingleThreadExecutor()
    private val retryMax = 3L
    private var retryCount = 0L
    private var retryDelay = 1000L
    private var doCallback: IGpOfficialLogoService.Callback? =null;
    override fun start(
        context: Context?,
        callback: IGpOfficialLogoService.Callback?,
    ) {
        Log.d(TAG, "IGpOfficialLogoService.start")
        retryCount = 0
        doCallback = callback
        singleExecutor.execute {
            val confCallBack = object : IGpOfficialLogoService.Callback {
                override fun onCurrentOfficialLogo(logoConfig: OfficialLogoConfig) {
                    Log.d(TAG, "onCurrentOfficialLogo: ${logoConfig}")
                    AnalyticsManager.logEvent("OfficialLogoConfig_conf_succ")
                    doCallback?.onCurrentOfficialLogo(logoConfig)
                }
                override fun onError(e: Exception) {
                    AnalyticsManager.logEvent("android_conf_failed")
                    Log.d(TAG, "onError: ${e}")
                    retry()
                    doCallback?.onError(e)
                }
                override fun onComplete() {
                    Log.d(TAG, "onComplete")
                    doCallback?.onComplete()
                }
            }
            try {
                val androidConf =  ApolloConfigUtil.fetchOfficialLogoConf()
                Log.i(TAG, "ApolloConfigUtil.fetchOfficialLogoConf $androidConf")
                confCallBack.onCurrentOfficialLogo(androidConf)
            } catch (e: Exception) {
                AnalyticsManager.logEvent("OfficialLogoConfig_conf_failed")
                Log.d(TAG, "android_conf_error: error $e")
                confCallBack.onError(e)
                retry()
            }
        }
    }

    private fun retry() {
        if (retryCount < retryMax) {
            retryCount++
            Log.d(TAG, "retryCount: $retryCount")
            singleExecutor.execute {
                val confCallBack = object : IGpOfficialLogoService.Callback {
                    override fun onCurrentOfficialLogo(logoConfig: OfficialLogoConfig) {
                        Log.d(TAG, "onCurrentOfficialLogo: ${logoConfig}")
                        AnalyticsManager.logEvent("OfficialLogoConfig_conf_succ")
                        doCallback?.onCurrentOfficialLogo(logoConfig)
                    }
                    override fun onError(e: Exception) {
                        AnalyticsManager.logEvent("OfficialLogoConfig_conf_failed")
                        Log.d(TAG, "onError: ${e}")
                        retry()
                        doCallback?.onError(e)
                    }
                    override fun onComplete() {
                        Log.d(TAG, "onComplete")
                        doCallback?.onComplete()
                    }
                }

                try {
                    Thread.sleep(retryDelay)
                    val androidConf =  ApolloConfigUtil.fetchOfficialLogoConf()
                    Log.i(TAG, "ApolloConfigUtil.fetchOfficialLogoConf $androidConf")
                    confCallBack.onCurrentOfficialLogo(androidConf)
                } catch (e: Exception) {
                    Log.d(TAG, "retry: InterruptedException $e")
                    AnalyticsManager.logEvent("OfficialLogoConfig_conf_failed")
                    Log.d(TAG, "start: error $e")
                    confCallBack.onError(e)
                } finally {
                    retry()
                }
            }
        } else {
            Log.d(TAG, "retryCount: $retryCount, retryMax: $retryMax, stop retry")
        }
    }
}