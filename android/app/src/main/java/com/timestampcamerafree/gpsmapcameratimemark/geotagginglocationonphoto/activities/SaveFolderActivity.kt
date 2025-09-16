package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities

import android.app.AlertDialog
import android.os.Bundle
import android.os.Environment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CheckBox
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.config
import java.io.File

class SaveFolderActivity : AppCompatActivity() {

    private lateinit var currentPathText: TextView
    private lateinit var recyclerView: RecyclerView
    private lateinit var createFolderBtn: View
    private lateinit var doneBtn: View
    private lateinit var adapter: FolderAdapter
    private var selectedFolder: File? = null
    private val dcimDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val windowInsetsController = ViewCompat.getWindowInsetsController(window.decorView)
        windowInsetsController?.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        windowInsetsController?.hide(WindowInsetsCompat.Type.statusBars())

        setContentView(R.layout.activity_save_folder)
        currentPathText = findViewById(R.id.current_path_text)
        recyclerView = findViewById(R.id.folder_recycler_view)
        createFolderBtn = findViewById(R.id.create_folder_btn)
        doneBtn = findViewById(R.id.done_btn)

        setupUI()
        setupListeners()
        loadFolders()

    }

    private fun setupUI() {
        currentPathText.text =  config.savePhotosFolder

        recyclerView.layoutManager = LinearLayoutManager(this)
        adapter = FolderAdapter(emptyList()) { folder ->
            selectedFolder = folder
            //设置
            config.savePhotosFolder = folder.absolutePath
            currentPathText.text = folder.absolutePath
            adapter.notifyDataSetChanged()
        }
        recyclerView.adapter = adapter
    }

    private fun setupListeners() {
        createFolderBtn.setOnClickListener {
            showCreateFolderDialog()
        }
        findViewById<ImageButton>(R.id.btnClose).setOnClickListener {
            finish()
        }
        doneBtn.setOnClickListener {
            selectedFolder?.let { folder ->
                config.savePhotosFolder = folder.absolutePath
                currentPathText.text = folder.absolutePath
                Toast.makeText(this, R.string.save_folder_updated, Toast.LENGTH_SHORT).show()
            } ?: run {
                Toast.makeText(this, R.string.no_folder_selected, Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun loadFolders() {
        val folders = dcimDir.listFiles()?.filter { 
            it.isDirectory && !it.name.startsWith(".") 
        } ?: emptyList()
        adapter.updateFolders(folders)
        selectedFolder = folders.firstOrNull { it.absolutePath == config.savePhotosFolder }
    }

    private fun showCreateFolderDialog() {
        val inputView = LayoutInflater.from(this).inflate(R.layout.dialog_input, null)
        val inputField = inputView.findViewById<TextView>(R.id.input_field)

        AlertDialog.Builder(this)
            .setTitle(R.string.create_new_folder)
            .setView(inputView)
            .setPositiveButton(R.string.create_new_folder) { _, _ ->
                val folderName = inputField.text.toString().trim()
                if (folderName.isNotEmpty()) {
                    val newFolder = File(dcimDir, folderName)
                    if (newFolder.exists()) {
                        Toast.makeText(this, R.string.folder_exists, Toast.LENGTH_SHORT).show()
                    } else {
                        if (newFolder.mkdir()) {
                            loadFolders()
                            Toast.makeText(this, R.string.folder_created, Toast.LENGTH_SHORT).show()
                        } else {
                            Toast.makeText(this, R.string.folder_creation_failed, Toast.LENGTH_SHORT).show()
                        }
                    }
                }
            }
            .setNegativeButton(R.string.k_cancle, null)
            .show()
    }

    inner class FolderAdapter(
        private var folders: List<File>,
        private val onFolderSelected: (File) -> Unit
    ) : RecyclerView.Adapter<FolderAdapter.FolderViewHolder>() {

        fun updateFolders(newFolders: List<File>) {
            folders = newFolders
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FolderViewHolder {
            val view = LayoutInflater.from(parent.context)
                .inflate(R.layout.item_folder, parent, false)
            return FolderViewHolder(view)
        }

        override fun onBindViewHolder(holder: FolderViewHolder, position: Int) {
            val folder = folders[position]
            holder.bind(folder)
        }

        override fun getItemCount() = folders.size

        inner class FolderViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
            private val folderName: TextView = itemView.findViewById(R.id.folder_name)
            private val checkbox: CheckBox = itemView.findViewById(R.id.folder_checkbox)

            fun bind(folder: File) {
                folderName.text = folder.name
                checkbox.isChecked = folder.absolutePath == selectedFolder?.absolutePath

                itemView.setOnClickListener {
                    onFolderSelected(folder)
                }
            }
        }
    }
}