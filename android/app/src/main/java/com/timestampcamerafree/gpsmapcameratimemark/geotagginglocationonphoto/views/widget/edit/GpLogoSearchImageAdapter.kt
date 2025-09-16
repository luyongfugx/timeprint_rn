package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.bumptech.glide.Priority
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.RequestOptions
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R

class GpLogoSearchImageAdapter(private val imageUrls: List<String>,private val onItemClick: (Int) -> Unit) :
    RecyclerView.Adapter<GpLogoSearchImageAdapter.ImageViewHolder>() {
   private  val TAG ="GpLogoSearchImageAdapter"
    // 配置Glide加载选项
    private val glideOptions = RequestOptions()
        .diskCacheStrategy(DiskCacheStrategy.ALL)  // 缓存所有版本图片
        .priority(Priority.HIGH)  // 提高加载优先级
        .placeholder(ColorDrawable(Color.LTGRAY))  // 加载中占位图
        .error(ColorDrawable(Color.RED))  // 错误占位图
        .override(800, 800)  // 限制图片最大尺寸

    inner  class ImageViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val imageView: ImageView = view.findViewById(R.id.imageView)
        var currentUrl: String? = null
        init {
            imageView.setOnClickListener {
                onItemClick(adapterPosition)
            }
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ImageViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.layout_logo_search_item_image, parent, false)
        return ImageViewHolder(view)
    }

    override fun getItemCount(): Int = imageUrls.size

    override fun onBindViewHolder(holder: ImageViewHolder, position: Int) {
        val url = imageUrls[position]
        holder.currentUrl = url
       // Log.d(TAG,"onBindViewHolder url:${url}")
        Glide.with(holder.itemView)
            .load(url)
            .apply(glideOptions)
            .into(holder.imageView)
    }

    override fun onViewRecycled(holder: ImageViewHolder) {
        super.onViewRecycled(holder)
        // 清除已回收的图片加载
        Glide.with(holder.itemView).clear(holder.imageView)
        holder.currentUrl = null
    }
}