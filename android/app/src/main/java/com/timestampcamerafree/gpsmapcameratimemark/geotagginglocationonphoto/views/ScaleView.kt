package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.util.AttributeSet
import android.util.Log
import android.view.LayoutInflater
import android.widget.RelativeLayout
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.toCameraSelector
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.toLensFacing
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.CameraSelectorManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.Config


@SuppressLint("CustomViewStyleable")
class ScaleView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : RelativeLayout(context, attrs, defStyleAttr) {
    private val TAG = "ScaleView"
    private var scale :Float = 1f
    private var circleSize: Int = dpToPx(24f)
    private var showBorder: Boolean = true
    private var textSize: Float = 12f
    private var textColor: Int = Color.WHITE

    var onScaleCallBack:Callback? = null
    private var borderColor: Int = Color.WHITE
    private var itemMarginBottom: Int = dpToPx(12f)

    private var values: List<String> = listOf("10", "2", "1","0.6")
    init {
        // 获取自定义属性
        context.obtainStyledAttributes(attrs, R.styleable.ScaleCircleView).apply {
            circleSize = getDimensionPixelSize(
                R.styleable.ScaleCircleView_circleSize,
                dpToPx(24f)
            )
            showBorder = getBoolean(R.styleable.ScaleCircleView_showBorder, true)
            textColor = getColor(R.styleable.ScaleCircleView_textColor, Color.WHITE)
            textSize = getDimension(R.styleable.ScaleCircleView_textSize, resources.getDimension(R.dimen.textSize12sp))
            borderColor = getColor(R.styleable.ScaleCircleView_borderColor, Color.WHITE)
            recycle()
        }

        setupView()
    }

    private fun setupView() {
        removeAllViews()
        // 创建容器
        val container = LayoutInflater.from(context).inflate(R.layout.view_scale_container, this, true)
        val circleContainer = container.findViewById<android.widget.LinearLayout>(R.id.circle_container)
        // 添加刻度项
        values.forEachIndexed { index, value ->
            //放大并选中的scale
            var  scaleCircleSize = circleSize
            var addSize =20;
            when {
                scale >6 ->{ if(index==0) { scaleCircleSize = circleSize+addSize}}
                scale in 2.0..6.0 -> { if(index==1) { scaleCircleSize = circleSize+addSize}}
                scale in 0.7..2.0 -> { if(index==2) { scaleCircleSize = circleSize+addSize}}
                else -> { if(index==3) { scaleCircleSize = circleSize+addSize}}
            }
            val circleView = ScaleCircleView(context).apply {
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    scaleCircleSize,
                    scaleCircleSize
                ).apply {
                    bottomMargin = if (index < values.size - 1) itemMarginBottom else 0
                }
                setShowBorder(showBorder)
                setText(value)
                setTextColor(textColor)
                setTextSize(textSize / resources.displayMetrics.scaledDensity) // 转换为sp
                setBorderColor(borderColor)
            }
        // 显示广角
            if(index==3){ //判断一下
                var  config =  Config.newInstance(App.context)
                if(CameraSelectorManager.supportWideAngel && config.lastUsedCameraLens.toCameraSelector() != CameraSelectorManager.frontCamera){
                    circleView.visibility = VISIBLE
                }
                else {
                    circleView.visibility = GONE
                }
            }

            //定义点击事件
            circleView.setOnClickListener {
                var curRatio = 0f
                Log.d(TAG,"circleView.setOnClickListener index:${index} scale:${scale}")
                when(index){
                    0 -> if(scale<6) {
                        curRatio = 10f
                    }
                    1 -> if(scale <=2 || scale >=6.0) {
                        curRatio = 2f
                    }
                    2 -> if(scale >=2 || scale<1){
                        curRatio = 1f
                    }
                    3 -> if(scale >=1){
                        curRatio = 0.6f
                    }
                }
                //设置curRatio
                CameraSelectorManager.curRatio = curRatio
                setScale(curRatio)
                onScaleCallBack?.onScaleClick(curRatio)
            }
            circleContainer.addView(circleView)
        }
    }



    // 更新刻度值
    private fun setScaleValues(values: List<String>) {
        this.values = values
        setupView()
    }
    //设置放大还是缩小
    fun setScale(newScale: Float){
        Log.d(TAG,"scaleView  setScale newScale:${newScale}")
        scale = newScale
        if(scale<1) {
            scale = 0.6f
        }
        val scaleText = if (scale.toInt().toFloat() == scale) {
            scale.toInt().toString()
        } else {
            String.format("%.1f", scale)
        }
        val scaleValues = when {
            scale > 6 -> listOf(scaleText, "2", "1","0.6")
            scale in 2.0..6.0 -> listOf("10", scaleText, "1","0.6")
            scale in 0.7..2.0 -> listOf("10", "2", scaleText,"0.6")
            else -> listOf("10", "2", "1","0.6")
        }
        Log.d(TAG,"scaleValues ${scaleValues}")

        setScaleValues(scaleValues)
    }

    private fun dpToPx(dp: Float): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }
    fun interface Callback {
        fun onScaleClick(t: Float)
    }
}
