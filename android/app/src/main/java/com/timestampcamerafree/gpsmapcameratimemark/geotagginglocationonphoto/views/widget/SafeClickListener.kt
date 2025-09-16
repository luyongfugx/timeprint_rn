package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget
import android.os.SystemClock
import android.util.SparseArray
import android.view.View
import android.view.ViewConfiguration
import androidx.fragment.app.FragmentActivity

 class SafeClickListener(private val clickListener: View.OnClickListener?,private val interval:Int) : View.OnClickListener {

    private val clickRecord = SparseArray<Long>(5)

//    private var clickListener: View.OnClickListener? = null

    constructor(clickListener: View.OnClickListener?):this(clickListener,ViewConfiguration.getJumpTapTimeout())

    constructor(clickListener: Function1<View,Unit>):this(View.OnClickListener { clickListener(it) },ViewConfiguration.getJumpTapTimeout())
    override fun onClick(it: View) {
        var context = it.context ?: return

        if (context is FragmentActivity
                && context.isFinishing) {
            return
        }
        val record = clickRecord[it.hashCode()]
        val curRecord = SystemClock.elapsedRealtime()
        if (record == null) {
            clickRecord.put(it.hashCode(), SystemClock.elapsedRealtime())
        } else if (curRecord - record < interval) {
            return
        }
        clickRecord.put(it.hashCode(), curRecord)

        clickListener?.onClick(it)
    }
}