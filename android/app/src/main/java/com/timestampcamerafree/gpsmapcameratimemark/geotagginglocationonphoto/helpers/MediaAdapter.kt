package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.content.Context
import android.graphics.Bitmap
import android.view.View
import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.util.Log
import android.view.ViewGroup
import android.widget.FrameLayout
import android.view.Gravity
import android.widget.ImageView
import android.widget.VideoView
import androidx.recyclerview.widget.RecyclerView
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.ColorDrawable
import android.media.MediaPlayer
import android.view.SurfaceHolder
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import android.util.TypedValue
import com.bumptech.glide.Glide

// 扩展函数：dp转px
fun Context.dpToPx(dp: Int): Int {
    return TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        dp.toFloat(),
        resources.displayMetrics
    ).toInt()
}

// 扩展函数：创建圆形边框Drawable
fun Context.createCircleBorderDrawable(
    fillColor: Int,
    strokeColor: Int,
    strokeWidth: Float
): GradientDrawable {
    return GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(fillColor)
        setStroke(strokeWidth.toInt(), strokeColor)
    }
}

/**
 * 相册adapter
 *
 * @property context
 * @property mediaList
 */
class MediaAdapter(
    private val context: Context,
    private val mediaList: List<Uri>
) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        val TAG = "MediaAdapter"
        const val TYPE_IMAGE = 1
        const val TYPE_VIDEO = 2
    }

    override fun getItemViewType(position: Int): Int {
        if (mediaList.isEmpty()){ //如果为空
            return  TYPE_IMAGE
        }
        try {
            val mimeType = context.contentResolver.getType(mediaList[position]) ?: return TYPE_IMAGE
            return if (mimeType.startsWith("video")) TYPE_VIDEO else TYPE_IMAGE
        }
        catch (e:Exception){
            return  TYPE_IMAGE
        }

    }


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return if (viewType == TYPE_IMAGE) {
            val frameLayout = FrameLayout(context).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(Color.BLACK)
            }

            val imageView = ImageView(context).apply {
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    Gravity.CENTER
                )
                scaleType = ImageView.ScaleType.FIT_CENTER
            }

            frameLayout.addView(imageView)
            ImageViewHolder(frameLayout, imageView)
        } else {
            val frameLayout = FrameLayout(context).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(Color.BLACK)
            }

            val videoView = VideoView(context).apply {
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    Gravity.CENTER
                )
            }

            // 添加播放按钮
            val playButton = ImageView(context).apply {
                layoutParams = FrameLayout.LayoutParams(
                    context.dpToPx(48), // 按钮大小
                    context.dpToPx(48),
                    Gravity.CENTER
                )
                setImageResource(android.R.drawable.ic_media_play)
                scaleType = ImageView.ScaleType.CENTER_INSIDE
                setColorFilter(Color.WHITE) // 设置图标颜色为白色
                
                // 添加圆形边框背景
                background = context.createCircleBorderDrawable(
                    fillColor = Color.TRANSPARENT,
                    strokeColor = Color.WHITE,
                    strokeWidth = context.dpToPx(2).toFloat()
                )
                // 设置内边距
                val padding = context.dpToPx(8)
                setPadding(padding, padding, padding, padding)
            }

            frameLayout.addView(videoView)
            frameLayout.addView(playButton)
            VideoViewHolder(frameLayout, videoView, playButton)
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        val uri = mediaList[position]
        if (holder is ImageViewHolder) {
            Glide.with(context).load(uri).into(holder.imageView)
        } else if (holder is VideoViewHolder) {
            Log.d(TAG,"VideoViewHolder onBindViewHolder uri:${uri}")
            
            // 重置视频状态
            holder.videoView.stopPlayback()
            holder.videoView.background = ColorDrawable(Color.BLACK)
            holder.playButton.visibility = View.VISIBLE
            // 加载封面
            Glide.with(context)
                .asBitmap()
                .load(uri)
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .placeholder(ColorDrawable(Color.BLACK))
                .error(ColorDrawable(Color.BLACK))
                .override(holder.videoView.width, holder.videoView.height)
                .into(object : CustomTarget<Bitmap>() {
                    override fun onResourceReady(
                        bitmap: Bitmap,
                        transition: Transition<in Bitmap>?
                    ) {
                        val drawable = BitmapDrawable(context.resources, bitmap).apply {
                            // 确保封面图不会拉伸变形
                            setAntiAlias(true)
                            setFilterBitmap(true)
                        }
                        holder.videoView.background = drawable
                        holder.videoCover = drawable
                    }

                    override fun onLoadCleared(placeholder: Drawable?) {
                        holder.videoView.background = placeholder
                    }
                })


            // 设置点击播放
            holder.playButton.setOnClickListener {
                it.visibility = View.GONE
                holder.videoView.background = null // 完全移除背景
                holder.playVideo(uri)
            }
        }
    }

    override fun getItemCount(): Int = mediaList.size

    class ImageViewHolder(
        val container: FrameLayout,
        val imageView: ImageView
    ) : RecyclerView.ViewHolder(container)

    class VideoViewHolder(
        val container: FrameLayout,
        val videoView: VideoView,
        val playButton: ImageView
    ) : RecyclerView.ViewHolder(container), SurfaceHolder.Callback {
        var videoCover: Drawable? = null
        private var isPrepared = false
        
        init {
            videoView.holder.addCallback(this)
            videoView.setOnPreparedListener { mp ->
                isPrepared = true
                mp.setOnVideoSizeChangedListener { _, width, height ->
                    if (width > 0 && height > 0) {
                        adjustVideoSize(width, height)
                    }
                }
            }
            videoView.setOnCompletionListener {
                playButton.visibility = View.VISIBLE
                videoView.background = videoCover
                videoView.seekTo(0) // 重置播放位置
                isPrepared = false // 重置准备状态
            }
            videoView.setOnErrorListener { _, what, extra ->
                Log.e(TAG, "Video playback error: $what, $extra")
                playButton.visibility = View.VISIBLE
                true // 表示已处理错误
            }
        }

        fun playVideo(uri: Uri) {
            if (!isPrepared) {
                videoView.setVideoURI(uri)
            }
            videoView.start()
        }

        private fun adjustVideoSize(videoWidth: Int, videoHeight: Int) {
            val viewWidth = videoView.width
            val viewHeight = videoView.height
            val aspectRatio = videoWidth.toFloat() / videoHeight.toFloat()

            val layoutParams = videoView.layoutParams as FrameLayout.LayoutParams
            if (viewWidth.toFloat() / viewHeight > aspectRatio) {
                // 视频比View更宽
                layoutParams.width = (viewHeight * aspectRatio).toInt()
                layoutParams.height = FrameLayout.LayoutParams.MATCH_PARENT
            } else {
                // 视频比View更高
                layoutParams.width = FrameLayout.LayoutParams.MATCH_PARENT
                layoutParams.height = (viewWidth / aspectRatio).toInt()
            }
            layoutParams.gravity = Gravity.CENTER
            videoView.layoutParams = layoutParams
        }

        override fun surfaceCreated(holder: SurfaceHolder) {
            // Surface准备好后重试播放
            if (videoView.currentPosition > 0) {
                videoView.seekTo(videoView.currentPosition)
                videoView.start()
            }
        }

        override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            // 处理Surface尺寸变化
        }

        override fun surfaceDestroyed(holder: SurfaceHolder) {
            // 释放资源
            isPrepared = false
        }
    }
}

