package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog

import android.app.Activity
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.appcompat.app.AppCompatActivity

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.DialogGpNewVersionBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.DialogGpRateBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.redirectToRateUs

/**
 * 新版更新
 *
 */
class GpNewVerDialog (val activity: Activity,val force:Boolean) {
    private var editDialog: GPBaseDialog? = null
    private val binding: DialogGpNewVersionBinding by lazy {
        DialogGpNewVersionBinding.inflate(LayoutInflater.from(activity), null, false)
    }
    fun show() {
        editDialog = GpDialog.init()
            .setContentView(binding.root)
            .setDimAmount(0.5f)
            .setMargin(0)
            .setOutCancel(false)
            .setShowBottom(true)
            .setHeight(ViewGroup.LayoutParams.WRAP_CONTENT)
        //去play store 更新
        binding.confirm.setOnClickListener {
            //去评分其实也就是去更新
            activity.redirectToRateUs()
            editDialog?.dismissAllowingStateLoss()
        }
        //强制更新的话把地步的ignore 按钮去掉
        if(force){
            binding.appeal.visibility =ViewGroup.GONE
        }
        else {
            binding.appeal.setOnClickListener{
                editDialog?.dismissAllowingStateLoss()
            }
        }

        editDialog?.show((activity as AppCompatActivity).supportFragmentManager)
    }
}
