package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog

import android.app.Activity
import android.util.Log
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.Toast
import android.widget.Toast.LENGTH_LONG
import androidx.appcompat.app.AppCompatActivity
import com.google.android.play.core.review.ReviewManagerFactory
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.ext.goContactActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.DialogGpRateBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.baseConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch


/**
 * 五星好评逻辑
 *
 * @property activity
 */
class GpRateStarsDialog(val activity: Activity) {
    private  var TAG = "GpRateStarsDialog"
    private var editDialog: GPBaseDialog? = null
    private val binding: DialogGpRateBinding by lazy {
        DialogGpRateBinding.inflate(LayoutInflater.from(activity), null, false)
    }
    private fun showInAppReview() {
        val reviewManager = ReviewManagerFactory.create(activity)
        CoroutineScope(Dispatchers.Main).launch {
            try {
                 reviewManager.requestReviewFlow().addOnCompleteListener {task ->
                     if (task.isSuccessful) {
                         val reviewInfo = task.result
                         reviewManager.launchReviewFlow(activity, reviewInfo)
                             .addOnCompleteListener {
                                 // 评价流程完成，无论成功与否
                                 AnalyticsManager.logEvent("rate_complete")
                                 activity.baseConfig.wasAppRated = true
                                 editDialog?.dismissAllowingStateLoss()
                                 Toast.makeText(activity, R.string.k_thank_you_use,LENGTH_LONG).show()
                                 Log.d(TAG, "Review flow finished.")
                             }
                     } else {
                         editDialog?.dismissAllowingStateLoss()
                         AnalyticsManager.logEvent("rate_review_failed")
                         Log.w(TAG, "Request Review Flow failed.", task.exception)
                     }
                 }

            } catch (e: Exception) {
                editDialog?.dismissAllowingStateLoss()
                AnalyticsManager.logEvent("rate_review_exception")
                Log.d(TAG,"showInAppReview Exception:${e}")
            }
        }
    }

    fun show() {
        AnalyticsManager.logEvent("show_rate_dialog")
        editDialog = GpDialog.init()
            .setContentView(binding.root)
            .setDimAmount(0.5f)
            .setMargin(0)
            .setOutCancel(false)
            .setShowBottom(true)
            .setHeight(ViewGroup.LayoutParams.WRAP_CONTENT)
        //去play store 评分
        binding.confirm.setOnClickListener {
            AnalyticsManager.logEvent("show_rate_app_review")
            showInAppReview()
        }
        binding.appeal.setOnClickListener{
            AnalyticsManager.logEvent("show_rate_go_contact")
            (activity as MainActivity).goContactActivity()
            editDialog?.dismissAllowingStateLoss()
        }
        editDialog?.show((activity as AppCompatActivity).supportFragmentManager)
    }
}
