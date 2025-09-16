package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.TextView
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.MultiShareMediaAdapter
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.MultiShareMediaLoader
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.MultiShareMediaItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils

class MultiShareActivity : SimpleActivity()  {
    companion object {
        const val TAG = "MultiShareActivity"
    }
    private lateinit var adapter: MultiShareMediaAdapter
    private val allItems = mutableListOf<MultiShareMediaItem>()
    private val selectedPhotos = mutableSetOf<MultiShareMediaItem.Photo>()

    @SuppressLint("NotifyDataSetChanged")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_gp_multi_share)
        val windowInsetsController = ViewCompat.getWindowInsetsController(window.decorView)
        windowInsetsController?.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        windowInsetsController?.hide(WindowInsetsCompat.Type.statusBars())
        updateSelectionUI()
        adapter = MultiShareMediaAdapter(allItems,
            onItemToggle = {
                if (it.isSelected) selectedPhotos.add(it) else selectedPhotos.remove(it)
                updateSelectionUI()
                AnalyticsManager.logEvent("multi_share_on_toggle")
            },
            onSelectAll = { header ->
                AnalyticsManager.logEvent("multi_share_select_all")
                val changed = allItems.filterIsInstance<MultiShareMediaItem.Photo>()
                    .filter { it.date == header.date }
                //先删除
                selectedPhotos.removeAll(changed.toSet())
                changed.forEach {
                    it.isSelected = !header.isAllSelected
                    //如果这次是选中，则添加
                    if(!header.isAllSelected){
                        selectedPhotos.add(it)
                    }
                }
                //设置
                header.isAllSelected = !header.isAllSelected
                adapter.notifyDataSetChanged()
                updateSelectionUI()
            })

        findViewById<RecyclerView>(R.id.recyclerView).apply {
            val spanCount = 3
            layoutManager = GridLayoutManager(this@MultiShareActivity, spanCount)
            (layoutManager as GridLayoutManager).spanSizeLookup = object : GridLayoutManager.SpanSizeLookup() {
                override fun getSpanSize(position: Int): Int {
                    return if (adapter?.getItemViewType(position) == MultiShareMediaAdapter.TYPE_HEADER) spanCount else 1
                }
            }
            adapter = this@MultiShareActivity.adapter
        }

        findViewById<View>(R.id.btnBack).setOnClickListener { finish() }

        findViewById<View>(R.id.shareBtn).setOnClickListener {
            AnalyticsManager.logEvent("multi_share_photo")
            shareSelectedPhotos()
        }

        loadMedia()
    }

    private fun loadMedia() {
        allItems.clear()
        allItems.addAll(MultiShareMediaLoader.loadImagesGroupedByDate(this))
        adapter.updateItems(allItems)
    }

    private fun updateSelectionUI() {
        val countText = "${selectedPhotos.size} ${GpUiUtils.getString(R.string.i_photos_selected)}"
        findViewById<TextView>(R.id.tvSelectedCount).text = countText
    }

    private fun shareSelectedPhotos() {
        if (selectedPhotos.isEmpty()) return

        val uris = selectedPhotos.map { it.uri }
        val intent = Intent().apply {
            action = if (uris.size == 1) Intent.ACTION_SEND else Intent.ACTION_SEND_MULTIPLE
            type = "image/*"
            if (uris.size == 1)
                putExtra(Intent.EXTRA_STREAM, uris.first())
            else
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, GpUiUtils.getString(R.string.i_share)))
    }
}
