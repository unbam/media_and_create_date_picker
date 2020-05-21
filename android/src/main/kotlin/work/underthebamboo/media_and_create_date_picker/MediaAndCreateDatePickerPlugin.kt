package work.underthebamboo.media_and_create_date_picker

import android.os.Build
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** MediaAndCreateDatePickerPlugin */
public class MediaAndCreateDatePickerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {

  private lateinit var channel : MethodChannel
  private var delegate: MediaAndCreateDatePickerDelegate? = null
  private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
  private var activityBinding: ActivityPluginBinding? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    pluginBinding = flutterPluginBinding
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      if (registrar.activity() == null) {
        return
      }

      val plugin = MediaAndCreateDatePickerPlugin()
      plugin.setup(registrar.messenger(), registrar, null)
    }
  }

  @RequiresApi(Build.VERSION_CODES.M)
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "pickMedia" -> {
        delegate?.pickMedia(result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    pluginBinding = null
  }

  override fun onDetachedFromActivity() {
    delegate?.let { activityBinding?.removeActivityResultListener(it) }
    delegate = null
    activityBinding = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
    val plugin = MediaAndCreateDatePickerPlugin()
    plugin.setup(pluginBinding!!.binaryMessenger, null, activityBinding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  private fun setup(messenger: BinaryMessenger?, registrar: Registrar?, activityBinding: ActivityPluginBinding?) {
    var delegate: MediaAndCreateDatePickerDelegate? = null

    if (registrar != null) {
      delegate = MediaAndCreateDatePickerDelegate(activity = registrar.activity())
      registrar.addActivityResultListener(delegate)
      registrar.addRequestPermissionsResultListener(delegate)
    } else if (activityBinding != null) {
      delegate = MediaAndCreateDatePickerDelegate(activity = activityBinding.activity)
      activityBinding.addActivityResultListener(delegate)
      activityBinding.addRequestPermissionsResultListener(delegate)
    }

    this.delegate = delegate

    channel = MethodChannel(messenger, "media_and_create_date_picker")
    channel.setMethodCallHandler(this)
  }
}

