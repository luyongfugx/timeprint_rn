package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities

import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.baseConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.config
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpDialogUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpHttpRequestApi
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpToastUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit.GpInputTextView

class ContactActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_contact)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }
        val back = findViewById<ImageButton>(R.id.back)
        back.setOnClickListener {
            finish()
        }
        val submit = findViewById<TextView>(R.id.submit)
        submit.setOnClickListener {
            val title = findViewById<GpInputTextView>(R.id.input_email)
            val user =  config.getAppUserId() ?: "user"

            val version = packageManager.getPackageInfo(packageName, 0).versionName
            val content = findViewById<GpInputTextView>(R.id.content)
             if (content.getText().isEmpty()){
                 GpToastUtil.showToastWithoutLimit( GpUiUtils.getString(R.string.k_please_input))
                 return@setOnClickListener
             }
            GpHttpRequestApi.feedback(title.getText(),user,version.toString(),content.getText()){ result ->
                if (result == 200) {
                    GpToastUtil.showToastWithoutLimit( GpUiUtils.getString(R.string.k_summit_success))
                    //
                    config.wasAppRated = true
                  //  finish()
                } else {
                    GpToastUtil.showToastWithoutLimit(  GpUiUtils.getString(R.string.k_network_exception_later))
                }
            }
        }
        
    }
}