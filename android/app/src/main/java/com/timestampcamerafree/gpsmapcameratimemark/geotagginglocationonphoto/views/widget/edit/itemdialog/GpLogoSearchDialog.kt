package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.itemdialog




import android.annotation.SuppressLint
import android.util.Log
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.fragment.app.FragmentActivity
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App.Companion.context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.databinding.DialogLogoSearchBinding
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.BitmapUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpDataStores
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKeys
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.SafeClickListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GPBaseDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpDialog
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewConvertListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog.GpViewHolder
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.GpLogoSearchImageAdapter
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.LogoPosition
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.WatermarkLogoItem
import java.io.File
import java.util.concurrent.atomic.AtomicReference


/**
 * logo 搜索
 *
 * @property activity
 * @property editItem
 * @property listener
 * @property saveItemFunc
 */
class GpLogoSearchDialog  (val activity: FragmentActivity, private val editItem: WatermarkItem, val listener: GpViewConvertListener, private var onChangeLogo: (WatermarkItem, Boolean) -> Unit, private var saveItemFunc: (WatermarkItem, Boolean) -> Unit) {
    private val TAG = "GpLogoSearchDialog"
    private var editDialog: GPBaseDialog? = null
    private lateinit var recyclerView: RecyclerView
    private lateinit var adapter: GpLogoSearchImageAdapter
    private lateinit var webView: WebView
    private var keyword = ""
    private var isGettingLogoImages = false
    private var retryCount = 0
    private val maxRetryCount = 3


    private val imageUrls:MutableList<String> = mutableListOf()


    private val binding: DialogLogoSearchBinding by lazy {
        DialogLogoSearchBinding.inflate(LayoutInflater.from(activity), null, false)
    }

    private fun showLoading(show: Boolean) {
        activity.runOnUiThread {
            binding.progressBar.visibility = if (show) View.VISIBLE else View.GONE
        }
    }
    @SuppressLint("NotifyDataSetChanged")
    private fun getLogoImages() {
        if (isGettingLogoImages) {
            Log.d(TAG, "getLogoImages already in progress, skipping")
            return
        }
        isGettingLogoImages = true

        val timePrintGetLogoImageJsFunc = """
                    function timePrintGetLogoImage(start, end) {
                      //console.log('timePrintGetLogoImageJsFunc'+start)
                      let divs = []
                      if (start && end) {
                        divs = Array.from(document.querySelectorAll('div[data-attrid="images universal"]')).slice(start, end)
                        //console.log('timePrintGetLogoImageJsFunc'+divs)
                      } else {
                        divs = Array.from(document.querySelectorAll('div[data-attrid="images universal"]'))
                    // console.log('timePrintGetLogoImageJsFunc'+divs)
                      }
                      let logos = []
                      
                      const prefix = 'data:image/gif;base64,';
                      divs.forEach(div => {
                        let img = div.querySelector('img')
                        if (img){
                          let imageUrl = img.getAttribute('src')
                          if(!imageUrl.startsWith(prefix)){
                               logos.push(imageUrl)
                          }
                        }
                      })
                      return logos
                    }
                    """
        webView.evaluateJavascript("javascript:${timePrintGetLogoImageJsFunc}") { result ->
            // result 是 JavaScript 函数的返回值 (如果有)
            val calljs = "timePrintGetLogoImage();"
            webView.evaluateJavascript("javascript:${calljs}"){logos->
               // Log.d(TAG, "JS timePrintGetLogoImageJsFunc returned: $logos")

                isGettingLogoImages = false
                if (logos.isNullOrEmpty() || logos == "[]") {
                    if (retryCount < maxRetryCount) {
                        retryCount++
                        Log.d(TAG, "Empty response, retrying... ($retryCount/$maxRetryCount)")
                        webView.postDelayed({
                            getLogoImages()
                        }, 1000) // 1秒后重试
                    } else {

                        showLoading(false)
                        //显示webview,如果没有结果
                        webView.animate()
                            .alpha(1f)
                            .setDuration(300)
                            .withEndAction {
                                webView.visibility = View.GONE
                            }
                            .start()
                       // Log.d(TAG, "Max retry count reached ($maxRetryCount), giving up")
                        //Toast.makeText(activity, "Failed to load logos after $maxRetryCount attempts", Toast.LENGTH_SHORT).show()
                    }
                } else {
                    retryCount = 0 // 成功获取后重置计数器
                    showLoading(false)
                    try {
                        // 解析JSON格式的logos数据
                        val type = object : TypeToken<List<String>>() {}.type
                        val logoList: List<String> = Gson().fromJson(logos, type)
                        if (logoList.isNotEmpty()) {
                           // logoList.forEach { Log.d(TAG,"logo url: ${it}") }
                            // 更新Adapter数据并添加过渡动画
                            activity.runOnUiThread {
                                Log.d(TAG,"logoList :${logoList.size}")
                                // 创建新适配器实例
                             //   val newAdapter = GpLogoSearchImageAdapter(logoList)
                                imageUrls.clear()
                                imageUrls.addAll(logoList)
                                adapter.notifyDataSetChanged()
                                // 平滑过渡效果
                                recyclerView.alpha = 0f
                                recyclerView.visibility = View.VISIBLE
                                recyclerView.animate()
                                    .alpha(1f)
                                    .setDuration(300)
                                    .start()
                                
                                webView.animate()
                                    .alpha(0f)
                                    .setDuration(300)
                                    .withEndAction {
                                        webView.visibility = View.GONE
                                    }
                                    .start()
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error parsing logos: $e")
                    }
                }
            }

        }
    }
    @SuppressLint("SetJavaScriptEnabled")
    private fun buildWebView() {
        val webSettings: WebSettings = webView.settings
        webSettings.javaScriptEnabled = true // 启用 JavaScript (如果你的网页需要JS交互)
        webSettings.domStorageEnabled = true // 启用 DOM 存储，对于一些现代网页是必需的
        webSettings.loadWithOverviewMode = true // 将页面缩放到适合屏幕的大小
        webSettings.useWideViewPort = true // 允许使用宽视口

        // 2. 设置 WebViewClient (处理页面导航、链接点击等)
        webView.webViewClient = object : WebViewClient() {
            // 当页面在 WebView 内部加载时调用，而不是启动外部浏览器
            @Deprecated("Deprecated in Java")
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                view?.loadUrl(url!!)
                return true
            }

            // 可选：当页面加载完成时调用
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                Log.d(TAG,"onPageFinished ${url}")
            if (keyword.isNotEmpty()){
                    retryCount = 0 // 新搜索时重置重试计数器
                    view?.postDelayed({
                        getLogoImages()
                    }, 1000) // 延迟1秒执行
                }
            }

            // 可选：处理加载错误
            @Deprecated("Deprecated in Java")
            override fun onReceivedError(view: WebView?, errorCode: Int, description: String?, failingUrl: String?) {
                super.onReceivedError(view, errorCode, description, failingUrl)
                // 例如，显示错误信息
            }
        }

    }
     private fun getSearchUrl(keyword: String): String {
         val googleUrl = "https://www.google.com/search?tbm=isch&q="
         val finalKeyWord = if (keyword.contains("logo")) keyword else "$keyword logo"
         val encodedKeyword = java.net.URLEncoder.encode(finalKeyWord, "UTF-8")
         return googleUrl + encodedKeyword
    }
    fun show(onMissCallback: GPBaseDialog.OnMissCallback?, onCancelCallback: GPBaseDialog.OnCancelCallback?,showPickerDialog: (() -> Unit)?) {
        editDialog = GpDialog.init()
            .setContentView(binding.root)
            .setConvertListener(object: GpViewConvertListener(){
                override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                    dialog?.let {}
                    listener.convertView(holder,dialog)
                }
            })
            .setDimAmount(0.5f)
            .setMargin(0)
            .setOutCancel(true)
            .setShowBottom(true)
            .setHeight(ViewGroup.LayoutParams.MATCH_PARENT)
        recyclerView = binding.imageRecyclerView
        webView = binding.webView
        //设置webView
        buildWebView()
        recyclerView.layoutManager = GridLayoutManager(activity, 2) // 2列网格
        adapter = GpLogoSearchImageAdapter(imageUrls){
            val imageUrl = imageUrls[it]
//            val imageFile = File(context.filesDir, fileName)
            val resultUri = BitmapUtils.saveBase64ToImage(imageUrl, context.filesDir,"search_logo_${System.currentTimeMillis()}.png")?.path
            Log.d(TAG,"removeBackground resultUri:$resultUri")

            if( editItem.logoInfo == null){
                editItem.logoInfo = WatermarkLogoItem().apply {
                    scale = 1f
                    position = LogoPosition.ON_WATER_MARK
                    selectLogoPath = resultUri
                    originLogoPath = resultUri
                }
            }
            editItem.logoInfo?.selectLogoPath = resultUri
            editItem.logoInfo?.originLogoPath = resultUri
            editItem.logoInfo?.isRemoveBg = false
            //通知activity
            activity.let {
                GpDataStores.put(GpStoreKeys.KEY_WATERMARK_UPDATE, it, Boolean::class.java, true)
            }
            saveItemFunc(editItem,true)
            onChangeLogo(editItem,true)

            editDialog?.dismissAllowingStateLoss()
        }
        recyclerView.adapter = adapter
        recyclerView.setItemViewCacheSize(60) // 增加缓存数量
        recyclerView.setHasFixedSize(true) // 优化性能

        recyclerView.visibility = View.GONE
        recyclerView.alpha = 1f
        //webView 透明，看不见
        webView.alpha = 0f
        var searchInput = binding.searchInput
        val focusedView = AtomicReference<View?>()
        binding.searchButton.setOnClickListener {
            webView.alpha = 0f
            Log.d(TAG,"do search ${searchInput.getText()}")
            keyword =  searchInput.getText()

            val url = getSearchUrl(keyword)
            showLoading(true)
            webView.loadUrl(url)
            GpKits.KeyBoard.hideSoftInput(App.context, it)
            AnalyticsManager.logEvent("search_logo_web")
            // 模拟搜索行为，可改为网络请求等
          //  Toast.makeText(this, "搜索暂未实现", Toast.LENGTH_SHORT)
        }

        searchInput.setSingleLine(true)
      //  searchInput.imeOptions = EditorInfo.IME_ACTION_DONE // 设置键盘Done按钮
        searchInput.setOnEditorActionListener { v, actionId, event ->
            if (actionId == EditorInfo.IME_ACTION_DONE ||
                (event != null && event.keyCode == KeyEvent.KEYCODE_ENTER)) {
                binding.searchButton.performClick()
                true
            } else {
                false
            }
        }
        searchInput.setOnFocusChangeListener { v: View, hasFocus: Boolean ->
            if (hasFocus) {
                focusedView.set(v)
                GpKits.KeyBoard.showSoftInput(App.context, v)
            }
        }
        editDialog?.setMissCallback(onMissCallback)

        binding.backIv.setOnClickListener(SafeClickListener(View.OnClickListener { v: View? ->
            onCancelCallback?.onCancel()
            editDialog?.dismissAllowingStateLoss()
        }))

        editDialog?.show(activity.supportFragmentManager)
    }

}