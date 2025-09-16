package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.annotation.SuppressLint
import android.graphics.Color
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.MultiShareMediaItem

class MultiShareMediaAdapter(
    private val items: MutableList<MultiShareMediaItem>,
    private val onItemToggle: (MultiShareMediaItem.Photo) -> Unit,
    private val onSelectAll: (MultiShareMediaItem.DateHeader) -> Unit
) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        const val TYPE_HEADER = 0
        private const val TYPE_PHOTO = 1

        const val TAG = "MultiShareMediaAdapter"

    }

    override fun getItemViewType(position: Int): Int {
        return when (items[position]) {
            is MultiShareMediaItem.DateHeader -> TYPE_HEADER
            is MultiShareMediaItem.Photo -> TYPE_PHOTO
        }
    }

    override fun getItemCount() = items.size

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            TYPE_HEADER -> HeaderViewHolder(
                LayoutInflater.from(parent.context)
                .inflate(R.layout.mutishare_item_date_header, parent, false))
            TYPE_PHOTO -> PhotoViewHolder(LayoutInflater.from(parent.context)
                .inflate(R.layout.mutishare_item_photo, parent, false))
            else -> throw IllegalArgumentException("Invalid type")
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (val item = items[position]) {
            is MultiShareMediaItem.DateHeader -> (holder as HeaderViewHolder).bind(item)
            is MultiShareMediaItem.Photo -> (holder as PhotoViewHolder).bind(item)
        }
    }

    inner class HeaderViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        fun bind(header: MultiShareMediaItem.DateHeader) {
            itemView.findViewById<TextView>(R.id.tvDate).text = header.date
            val checkAllBtn = itemView.findViewById<ImageView>(R.id.checkAllBtn)
            checkAllBtn.setOnClickListener {
                onSelectAll(header)
            }
            val drawable = if (header.isAllSelected) R.drawable.ic_check_circle_vector else R.drawable.circle_white_border
            checkAllBtn.setImageResource(drawable)
        }
    }

    inner class PhotoViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        private val imageView = itemView.findViewById<ImageView>(R.id.imageView)
        private val checkView = itemView.findViewById<ImageView>(R.id.checkView)

        fun bind(photo: MultiShareMediaItem.Photo) {
            Glide.with(imageView).load(photo.uri).into(imageView)
            val drawable = if (photo.isSelected) R.drawable.ic_check_circle_vector else R.drawable.circle_white_border
            checkView.setImageResource(drawable)
//            checkView.visibility = if (photo.isSelected) View.VISIBLE else View.GONE
            itemView.setOnClickListener {
                photo.isSelected = !photo.isSelected
               // notifyItemChanged(bindingAdapterPosition)
                //notifyItemChanged()
                notifyDataSetChanged()
                onItemToggle(photo)
            }
        }
    }

    @SuppressLint("NotifyDataSetChanged")
    fun updateItems(newItems: List<MultiShareMediaItem>) {
        items.addAll(newItems)
        notifyDataSetChanged()
    }
}
