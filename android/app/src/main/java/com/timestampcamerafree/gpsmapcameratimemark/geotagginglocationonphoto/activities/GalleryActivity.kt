package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities

import android.annotation.SuppressLint
import android.app.Activity
import android.content.ContentUris
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.view.View
import android.widget.ImageButton
import android.widget.Toast
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.RequiresApi
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.RecyclerView
import androidx.viewpager2.widget.ViewPager2
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.MediaAdapter
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils
import java.io.File

/**
 * 相册页面
 *
 */
fun ViewPager2.findCurrentViewHolder(): RecyclerView.ViewHolder? {
    val recyclerView = this.getChildAt(0) as? RecyclerView ?: return null
    return recyclerView.findViewHolderForAdapterPosition(currentItem)
}
class GalleryActivity : SimpleActivity() {
    companion object {
        const val TAG = "GalleryActivity"
    }
    private lateinit var viewPager: ViewPager2
    private val mediaList = mutableListOf<Uri>()
    private var currentVideoHolder: MediaAdapter.VideoViewHolder? = null

    private fun stopCurrentVideo() {
        currentVideoHolder?.videoView?.stopPlayback()
        currentVideoHolder = null
    }

    private val pageChangeCallback = object : ViewPager2.OnPageChangeCallback() {
        override fun onPageSelected(position: Int) {
            handleVideoPlayback(position)
        }
    }


    private fun handleVideoPlayback(newPosition: Int) {
        stopCurrentVideo()
        val adapter = viewPager.adapter as? MediaAdapter ?: return
        if (adapter.getItemViewType(newPosition) == MediaAdapter.TYPE_VIDEO) {
            lifecycleScope.launch {
                delay(300) // 等待ViewPager完成滚动动画
                val holder = viewPager.findCurrentViewHolder() as? MediaAdapter.VideoViewHolder
               // holder?.videoView?.start()
                currentVideoHolder = holder
            }
        }
    }

    @SuppressLint("NotifyDataSetChanged")
    private val deleteRequestLauncher = registerForActivityResult(
        ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val pos = viewPager.currentItem
            if (pos < 0 || pos >= mediaList.size) {

            }
            else {
                mediaList.removeAt(pos)
                viewPager.adapter?.notifyDataSetChanged()
            }

        }
        // 处理完成后清除URI
    }

    @RequiresApi(Build.VERSION_CODES.R)
    override fun onPause() {
        stopCurrentVideo()
        super.onPause()
    }

    override fun onDestroy() {
        stopCurrentVideo()
        super.onDestroy()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_gp_gallery)
        val windowInsetsController = ViewCompat.getWindowInsetsController(window.decorView)
        windowInsetsController?.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        windowInsetsController?.hide(WindowInsetsCompat.Type.statusBars())

        viewPager = findViewById(R.id.viewPager)
        findViewById<ImageButton>(R.id.btnClose).setOnClickListener {
            //onBackPressed()
            finish()
        }
        findViewById<View>(R.id.delBtn).setOnClickListener {
            val pos = viewPager.currentItem
            if (pos < 0 || pos >= mediaList.size) {
                return@setOnClickListener
            }
            val uri = mediaList[pos]
            AnalyticsManager.logEvent("del_photo")
            deleteMedia(uri)
        }
        //底部分享
        findViewById<View>(R.id.shareBtn).setOnClickListener {
            val currentUri = mediaList.getOrNull(viewPager.currentItem)
            if (currentUri != null) {
                shareMedia(listOf(currentUri))
                AnalyticsManager.logEvent("single_share_photo")
            }
        }
        //顶部多重分享
        findViewById<View>(R.id.tvShareMultiple).setOnClickListener {
            AnalyticsManager.logEvent("go_multi_share")
            val intent = Intent(this, MultiShareActivity::class.java)
            startActivity(intent)
        }

        //申请权限
        handleStoragePermission{
            loadMediaFromGallery()
        }
    }

    /**
     * share
     *
     * @param uris
     */
    private fun shareMedia(uris: List<Uri>) {
        val intent = Intent().apply {
            action = if (uris.size == 1) Intent.ACTION_SEND else Intent.ACTION_SEND_MULTIPLE
            type = contentResolver.getType(uris[0]) ?: "*/*"
            if (uris.size == 1) {
                putExtra(Intent.EXTRA_STREAM, uris[0])
            } else {
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(intent, GpUiUtils.getString(R.string.i_share))
        startActivity(chooser)
    }


    @SuppressLint("NotifyDataSetChanged")
    private fun deleteMedia(uri: Uri) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val intentSender = MediaStore.createDeleteRequest(contentResolver, listOf(uri)).intentSender
                deleteRequestLauncher.launch(
                    IntentSenderRequest.Builder(intentSender).build()
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // For Android 10 (Q) but not R
                val rows = contentResolver.delete(uri, null, null)
                if (rows > 0) {
                    val pos = viewPager.currentItem
                    if (pos >= 0 && pos < mediaList.size) {
                        mediaList.removeAt(pos)
                        viewPager.adapter?.notifyDataSetChanged()
                    }
                }
            } else {
                // For versions below Q
                val filePath = getFilePathFromUri(uri)
                filePath?.let {
                    val file = File(it)
                    if (file.exists() && file.delete()) {
                        val pos = viewPager.currentItem
                        if (pos >= 0 && pos < mediaList.size) {
                            mediaList.removeAt(pos)
                            viewPager.adapter?.notifyDataSetChanged()
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Toast.makeText(this, R.string.i_save_photo_failed, Toast.LENGTH_SHORT).show()
        }
    }

    private fun getFilePathFromUri(uri: Uri): String? {
        val projection = arrayOf(MediaStore.Images.Media.DATA)
        val cursor = contentResolver.query(uri, projection, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val columnIndex = it.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                return it.getString(columnIndex)
            }
        }
        return null
    }
    private fun loadMediaFromGallery() {
        lifecycleScope.launch(Dispatchers.IO) {
            val projection = arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.MEDIA_TYPE
            )
            val selection = (MediaStore.Files.FileColumns.MEDIA_TYPE + "=" +
                    MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE + " OR " +
                    MediaStore.Files.FileColumns.MEDIA_TYPE + "=" +
                    MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO)

            val sortOrder = "${MediaStore.Files.FileColumns.DATE_ADDED} DESC"
            val collection = MediaStore.Files.getContentUri("external")

            val mediaUris = mutableListOf<Uri>()
            val query = contentResolver.query(collection, projection, selection, null, sortOrder)

            query?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                val typeColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE)

                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idColumn)
                    val type = cursor.getInt(typeColumn)
                    val uri = when (type) {
                        MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE ->
                            ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                        MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO ->
                            ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
                        else -> null
                    }
                    uri?.let { mediaUris.add(it) }
                }
            }

            withContext(Dispatchers.Main) {
                mediaList.clear()
                mediaList.addAll(mediaUris)
                viewPager.adapter = MediaAdapter(this@GalleryActivity, mediaList)
                viewPager.registerOnPageChangeCallback(pageChangeCallback)
                // 初始加载时检查第一个item是否是视频
                if (mediaList.isNotEmpty()) {
                    handleVideoPlayback(0)
                }
            }
        }
    }
}
