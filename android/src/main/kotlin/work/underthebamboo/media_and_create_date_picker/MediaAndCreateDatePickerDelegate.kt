package work.underthebamboo.media_and_create_date_picker

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import androidx.loader.app.LoaderManager
import androidx.loader.content.Loader
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class MediaAndCreateDatePickerDelegate(private val activity: Activity) : PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener, LoaderManager.LoaderCallbacks<String> {
    private var channelResult : MethodChannel.Result? = null

    companion object {
        const val REQUEST_CODE = 1000
        const val REQUEST_PERMISSION = 1001
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            REQUEST_CODE -> {
                if(data == null) {
                    val result = errorResult("cancel", "")
                    channelResult?.success(result)
                    return true
                }

                val uri = data.data as Uri
                var contentUri: Uri? = null
                val projection: Array<out String>? = null
                var selection: String? = null
                var selectionArgs: Array<out String>? = null
                val docId: String = DocumentsContract.getDocumentId(uri)

                when (uri.authority) {
                    "com.android.providers.media.documents" -> {
                        val split = docId.split(":").toTypedArray()
                        contentUri = MediaStore.Files.getContentUri("external")
                        selection = "_id=?"
                        selectionArgs = arrayOf(split[1])
                    }
                    "com.android.providers.downloads.documents" -> {
                        // Error
                        contentUri = ContentUris.withAppendedId(
                          Uri.parse("content://downloads/all_downloads"), docId.toLong())
                    }
                    "com.android.externalstorage.documents" -> {
                        // Unconfirmed
                        contentUri = uri
                    }
                    else -> {
                        val result = errorResult("error", "NOT_SUPPORTED")
                        channelResult?.success(result)
                        return true
                    }
                }

                val jsonStr = result(contentUri!!, projection, selection, selectionArgs)
                channelResult?.success(jsonStr)
                return true
            }
            else -> {
                false
            }
        }
    }

    override fun onCreateLoader(id: Int, args: Bundle?): Loader<String> {
        TODO("Not yet implemented")
    }

    override fun onLoadFinished(loader: Loader<String>, data: String?) {
        TODO("Not yet implemented")
    }

    override fun onLoaderReset(loader: Loader<String>) {
        TODO("Not yet implemented")
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
        if (REQUEST_PERMISSION != requestCode) {
            return false
        }

        val permissionGranted =
          grantResults?.count()!! > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED

        if (permissionGranted) {
            startActivity()
            return true
        }

        val result = errorResult("error", "PERMISSION_DENIED")
        channelResult?.success(result)
        return false
    }

    @RequiresApi(Build.VERSION_CODES.M)
    fun pickMedia(result: MethodChannel.Result) {
        channelResult = result

        val permissionCheck: Int = activity.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE)
        if (permissionCheck != PackageManager.PERMISSION_GRANTED) {
            activity.requestPermissions(arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE), REQUEST_PERMISSION)
        }
        else {
            startActivity()
        }
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    private fun startActivity() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        intent.putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*"))
        intent.type = "image/*,video/*"

        // open picker
        activity.startActivityForResult(intent, REQUEST_CODE)
    }

    @SuppressLint("SimpleDateFormat")
    private fun result(contentUri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?) : String {
        val df = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        var path: String = ""
        var dateStr: String = ""
        var type: String = "unknown"

        activity.contentResolver.query(contentUri, null, selection, selectionArgs, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                path = cursor.getString(cursor.getColumnIndex(MediaStore.Files.FileColumns.DATA))
                val date = Date(cursor.getLong(cursor.getColumnIndex(MediaStore.Images.Media.DATE_TAKEN)))
                dateStr = df.format(date)
                type = if (cursor.getString(cursor.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE)).startsWith("image")) "image" else "video"
            }
        }

        //println("path: $path")
        //println("createDate: $dateStr")
        //println("type: $type")

        // JSON
        val map = mutableMapOf<String, String>()
        map["path"] = path
        map["createDate"] = dateStr
        map["mediaType"] = type
        map["resultType"] = "success"
        map["error"] = ""

        return "${JSONObject(map)}"
    }

    private fun errorResult(resultType: String, errMessage: String) : String {
        // JSON
        val map = mutableMapOf<String, String>()
        map["path"] = ""
        map["createDate"] = ""
        map["mediaType"] = "unknown"
        map["resultType"] = resultType
        map["error"] = errMessage

        return "${JSONObject(map)}"
    }
}