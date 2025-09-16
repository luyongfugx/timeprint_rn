package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit


import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R

/**
 * 选择
 *
 */
class GpEditStampFragment : Fragment() {
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.layout_edit_stamp, container, false)
    }
}
