package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.util.Consumer
import java.io.File
import java.io.FileFilter
import java.io.FilenameFilter
import java.io.IOException
import java.net.URI
import java.net.URL
import java.nio.file.Path
import kotlin.collections.ArrayList
import kotlin.collections.HashMap
import kotlin.jvm.Throws

private var fileCache = ArrayList<File>()
private var fileRefCount = HashMap<File, Int>()
fun Int.padStart(length: Int, pad: Char): String {
    return toString().padStart(length, pad)
}
fun File.cacheFile():File {
    var find = fileCache.find { it.path == this.path }
    if (find == null) {
        synchronized(fileCache) {
            find = fileCache.find { it.path == this.path }
            if (find == null) {
                fileCache.add(this)
                find = this
            }
        }
    }
    return find!!
}


fun File.proxy():FileProxy {
    return FileProxy(this.path)
}

fun File.equals(other:Any?):Boolean {
    this.cacheFile()
    return this.equals(other)
}


fun File.hashCode():Int {
    this.cacheFile()
    return this.hashCode()
}


fun File.toString():String {
    this.cacheFile()
    return this.toString()
}

fun File.compareTo(other:File):Int {
    this.cacheFile()

    return this.compareTo(other)
}

fun File.getName():String {
    this.cacheFile()

    return this.getName()
}

fun File.getParent():String? {
    this.cacheFile()

    return this.getParent()
}

fun File.getParentFile():File? {
    this.cacheFile()

    return this.getParentFile()
}

fun File.getPath():String {
    this.cacheFile()

    return this.getPath()
}

fun File.isAbsolute():Boolean {
    this.cacheFile()

    return this.isAbsolute()
}

fun File.getAbsolutePath():String {
    this.cacheFile()

    return this.getAbsolutePath()
}

fun File.getAbsoluteFile():File {
    this.cacheFile()

    return this.getAbsoluteFile()
}

fun File.getCanonicalPath():String {
    this.cacheFile()

    return this.getCanonicalPath()
}

fun File.getCanonicalFile():File {
    this.cacheFile()

    return this.getCanonicalFile()
}

fun File.toURL():URL {
    this.cacheFile()

    return this.toURL()
}

fun File.toURI():URI {
    this.cacheFile()

    return this.toURI()
}

fun File.canRead():Boolean {
    this.cacheFile()

    return this.canRead()
}

fun File.canWrite():Boolean {
    this.cacheFile()
    return this.canWrite()
}

fun File.exists():Boolean {
    this.cacheFile()
    return this.exists()
}

fun File.isDirectory():Boolean {
    this.cacheFile()
    return this.isDirectory()
}

fun File.isFile():Boolean {
    this.cacheFile()
    return this.isFile()
}

fun File.isHidden():Boolean {
    this.cacheFile()
    return this.isHidden()
}

fun File.lastModified():Long {
    this.cacheFile()
    return this.lastModified()
}

fun File.length():Long {
    this.cacheFile()
    return this.length()
}

fun File.createNewFile():Boolean {
    this.cacheFile()
    return this.createNewFile()
}

fun File.delete():Boolean {
    this.cacheFile()
    return this.delete()
}

fun File.deleteOnExit() {
    this.cacheFile()
    this.deleteOnExit()
}

fun File.list():Array<String>? {
    this.cacheFile()
    return this.list()
}

fun File.list(filter:FilenameFilter?):Array<String>? {
    this.cacheFile()
    return this.list(filter)
}

fun File.listFiles():Array<File>? {
    this.cacheFile()
    return this.listFiles()
}

fun File.listFiles(filter:FilenameFilter?):Array<File>? {
    this.cacheFile()
    return this.listFiles(filter)
}

fun File.listFiles(filter:FileFilter?):Array<File>? {
    this.cacheFile()
    return this.listFiles(filter)
}

fun File.mkdir():Boolean {
    this.cacheFile()
    return this.mkdir()
}

fun File.mkdirs():Boolean {
    this.cacheFile()
    return this.mkdirs()
}

fun File.renameTo(dest:File):Boolean {
    this.cacheFile()
    return this.renameTo(dest)
}

fun File.setLastModified(time:Long):Boolean {
    this.cacheFile()
    return this.setLastModified(time)
}

fun File.setReadOnly():Boolean {
    this.cacheFile()
    return this.setReadOnly()
}

fun File.setWritable(writable:Boolean, ownerOnly:Boolean):Boolean {
    this.cacheFile()
    return this.setWritable(writable, ownerOnly)
}

fun File.setWritable(writable:Boolean):Boolean {
    this.cacheFile()
    return this.setWritable(writable)
}

fun File.setReadable(readable:Boolean, ownerOnly:Boolean):Boolean {
    this.cacheFile()
    return this.setReadable(readable, ownerOnly)
}

fun File.setReadable(readable:Boolean):Boolean {
    this.cacheFile()
    return this.setReadable(readable)
}

fun File.setExecutable(executable:Boolean, ownerOnly:Boolean):Boolean {
    this.cacheFile()
    return this.setExecutable(executable, ownerOnly)
}

fun File.setExecutable(executable:Boolean):Boolean {
    this.cacheFile()
    return this.setExecutable(executable)
}

fun File.canExecute():Boolean {
    this.cacheFile()
    return this.canExecute()
}

fun File.getTotalSpace():Long {
    this.cacheFile()
    return this.getTotalSpace()
}

fun File.getFreeSpace():Long {
    this.cacheFile()
    return this.getFreeSpace()
}

fun File.getUsableSpace():Long {
    this.cacheFile()
    return this.getUsableSpace()
}

@RequiresApi(Build.VERSION_CODES.O) fun File.toPath():Path {
    this.cacheFile()
    return this.toPath()
}


var actionMap:HashMap<Int, MutableList<Consumer<File>>> = HashMap<Int, MutableList<Consumer<File>>>()



enum class Action {
    DELETE,
}

fun registerAction(action:Action, runnable:Consumer<File>) {
    try {
        val get = actionMap.get(action.ordinal)
        if (get!= null) {
            get!!.add(runnable)
        } else {
            val list:MutableList<Consumer<File>> = ArrayList<Consumer<File>>()
            list.add(runnable)
            actionMap.put(action.ordinal, list)
        }
    } catch (e:Throwable) {
        e.printStackTrace()
    }
}

fun unRegisterAction(action:Action, runnable:Consumer<File>) {
    try {
        val get = actionMap.get(action.ordinal)
        get?.remove(runnable)
    } catch (e:Throwable) {
        e.printStackTrace()
    }
}

private const val TAG = "FileProxy"


fun dispatchAction(action:Action,file:File) {
    try {
        val get = actionMap.get(action.ordinal)
        val currentTimeMillis = System.currentTimeMillis()
        get?.forEach {
            it.accept(file)
        }
        if (System.currentTimeMillis() - currentTimeMillis  > 20){
            Log.e(TAG, "dispatchAction: $action is more than 20 ms,check code and run by post")
        }
    } catch (e:Throwable) {
        e.printStackTrace()
    }
}



class FileProxy:File {
    constructor(pathname:String?):super(pathname ?: "")
    constructor(parent:String?, child:String):super(parent, child)
    constructor(parent:File?, child:String):super(parent, child)
    constructor(uri:URI):super(uri)

    init {
        try {
            val find = this.cacheFile()
            synchronized(fileRefCount){
                fileRefCount[find] = fileRefCount[find] ?: 0 + 1
            }
        }catch (e:Throwable){
            e.printStackTrace()
        }

    }


    override fun equals(other:Any?):Boolean {
        return super.equals(other)
    }


    override fun hashCode():Int {
        return super.hashCode()
    }


    override fun toString():String {
        return super.toString()
    }

    override fun compareTo(other:File):Int {
        return super.compareTo(other)
    }

    override fun getName():String {
        return super.getName()
    }

    override fun getParent():String? {
        return super.getParent()
    }

    override fun getParentFile():File? {
        return super.getParentFile()
    }

    override fun getPath():String {
        return super.getPath()
    }

    override fun isAbsolute():Boolean {
        return super.isAbsolute()
    }

    override fun getAbsolutePath():String {
        return super.getAbsolutePath()
    }

    override fun getAbsoluteFile():File {
        return super.getAbsoluteFile()
    }

    @Throws(IOException::class) override fun getCanonicalPath():String {
        return super.getCanonicalPath()
    }

    override fun getCanonicalFile():File {
        return super.getCanonicalFile()
    }

    override fun toURL():URL {
        return super.toURL()
    }

    override fun toURI():URI {
        return super.toURI()
    }

    override fun canRead():Boolean {
        return super.canRead()
    }

    override fun canWrite():Boolean {
        return super.canWrite()
    }

    override fun exists():Boolean {
        return super.exists()
    }

    override fun isDirectory():Boolean {
        return super.isDirectory()
    }

    override fun isFile():Boolean {
        return super.isFile()
    }

    override fun isHidden():Boolean {
        return super.isHidden()
    }

    override fun lastModified():Long {
        return super.lastModified()
    }

    override fun length():Long {
        return super.length()
    }

    override fun createNewFile():Boolean {
        return super.createNewFile()
    }

    override fun delete():Boolean {
        dispatchAction(Action.DELETE,this)
        return super.delete()
    }

    override fun deleteOnExit() {
        super.deleteOnExit()
    }

    override fun list():Array<String>? {
        return super.list()
    }

    override fun list(filter:FilenameFilter?):Array<String>? {
        return super.list(filter)
    }

    override fun listFiles():Array<File>? {
        return super.listFiles()
    }

    override fun listFiles(filter:FilenameFilter?):Array<File>? {
        return super.listFiles(filter)
    }

    override fun listFiles(filter:FileFilter?):Array<File>? {
        return super.listFiles(filter)
    }

    override fun mkdir():Boolean {
        return super.mkdir()
    }

    override fun mkdirs():Boolean {
        return super.mkdirs()
    }

    override fun renameTo(dest:File):Boolean {
        return super.renameTo(dest)
    }

    override fun setLastModified(time:Long):Boolean {
        return super.setLastModified(time)
    }

    override fun setReadOnly():Boolean {
        return super.setReadOnly()
    }

    override fun setWritable(writable:Boolean, ownerOnly:Boolean):Boolean {
        return super.setWritable(writable, ownerOnly)
    }

    override fun setWritable(writable:Boolean):Boolean {
        return super.setWritable(writable)
    }

    override fun setReadable(readable:Boolean, ownerOnly:Boolean):Boolean {
        return super.setReadable(readable, ownerOnly)
    }

    override fun setReadable(readable:Boolean):Boolean {
        return super.setReadable(readable)
    }

    override fun setExecutable(executable:Boolean, ownerOnly:Boolean):Boolean {
        return super.setExecutable(executable, ownerOnly)
    }

    override fun setExecutable(executable:Boolean):Boolean {
        return super.setExecutable(executable)
    }

    override fun canExecute():Boolean {
        return super.canExecute()
    }

    override fun getTotalSpace():Long {
        return super.getTotalSpace()
    }

    override fun getFreeSpace():Long {
        return super.getFreeSpace()
    }

    override fun getUsableSpace():Long {
        return super.getUsableSpace()
    }

    override fun toPath():Path {
        return super.toPath()
    }
}

