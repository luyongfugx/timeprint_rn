package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit

import android.annotation.SuppressLint
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver.OnGlobalLayoutListener
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpDataStores
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKeys
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager


/**
 * 选择
 *
 */
class GpSelectStampFragment : Fragment() {
    private lateinit var recyclerView: RecyclerView
    private val TAG = "GpSelectStampFragment"
    private val adapter: GpSelectStampAdapter by lazy {
                 GpSelectStampAdapter(WatermarkManager.watermarkTemplateList!!,requireActivity())
    }


    @SuppressLint("NotifyDataSetChanged")
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val view:View = inflater.inflate(R.layout.layout_select_stamp, container, false)
        recyclerView = view.findViewById(R.id.select_stamp_recycler_view)
        recyclerView.layoutManager = GridLayoutManager(requireActivity(), 2)
        WatermarkManager.watermarkTemplateList?.forEach {
            it.isSelect = it.watermarkModel?.id == WatermarkManager.getSelectWatermarkModel().id
        }


        adapter.action = { isClick, wm, position, isAutoClick ->
            if (wm.isSelect == true) { // 点击已选中水印，打开编辑页
                //通知GpTabsEdit 跳转到 edittab
                GpDataStores.put(GpStoreKeys.KEY_SHOW_STAMP_EDIT_TAB, requireActivity(), Boolean::class.java, true)
            }
            else {
                val selectItem = WatermarkManager.watermarkTemplateList?.firstOrNull { it.isSelect == true }

                selectItem?.let {
                    selectItem.isSelect = false
                    val selectPosition = WatermarkManager.watermarkTemplateList?.indexOf(selectItem)
                    selectPosition?.let { adapter.notifyItemChanged(it) }
                }
                wm.isSelect = true
                adapter.notifyItemChanged(position)
                //修改
                wm.watermarkModel?.id?.let {
                    activity?.config?.selectedWaterMarkId = it
                    WatermarkManager.changeSelectWatermarkModel(it)
                }
                scrollToPosition(position)
                activity?.let {
                    GpDataStores.put(GpStoreKeys.WATERMARK_ID_CHANGE, it, Boolean::class.java, true)
                }
            }


        }
        recyclerView.viewTreeObserver.addOnGlobalLayoutListener(object : OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                recyclerView.viewTreeObserver.removeOnGlobalLayoutListener(this)
                val selectId = WatermarkManager.watermarkTemplateList?.firstOrNull { it.isSelect == true }
                selectId?.let {
                    val selectPosition = WatermarkManager.watermarkTemplateList?.indexOf(selectId)
                    selectPosition?.let {
                        initScrollToPosition(selectPosition)

                    }
                }
                // RecyclerView 布局完成
                // 在这里执行你的操作
            }
        })
        recyclerView.adapter = adapter

        return view
    }
    private fun initScrollToPosition(position: Int) {
        recyclerView.post {
            val recyclerViewHeight = recyclerView.height
            val targetViewHeight = 329
            var y = if (position%2==1) {
             targetViewHeight*((position-1)/2)
            } else targetViewHeight*(position/2)
            val targetScrollPosition = calculateTargetScrollPosition(
                recyclerViewHeight,
                y,
                targetViewHeight
            )
            recyclerView.smoothScrollBy(0, targetScrollPosition)
        }
    }
    private fun scrollToPosition(position: Int) {
        recyclerView.post {
            val recyclerViewHeight = recyclerView.height
            val targetView = recyclerView.layoutManager!!.findViewByPosition(position)
            if (targetView != null) {
                val targetViewHeight = targetView.height
                val targetScrollPosition = calculateTargetScrollPosition(
                    recyclerViewHeight,
                    targetView.y.toInt(),
                    targetViewHeight
                )
              //  Log.i(TAG,"targetScrollPosition:$targetScrollPosition targetView.y:${targetView.y} targetViewHeight :$targetViewHeight")
                recyclerView.smoothScrollBy(0, targetScrollPosition)
            }

        }
    }
    private fun calculateTargetScrollPosition(
        recyclerViewHeight: Int,
        targetY: Int,
        targetViewHeight: Int
    ): Int {
        val targetScrollPosition =
            targetY - (recyclerViewHeight - targetViewHeight) / 2
        return targetScrollPosition.toDouble().toInt()
    }

}
