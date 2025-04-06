package com.your.package.name

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
  private val CHANNEL = "update_channel"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call, result ->
  if (call.method == "installApk") {
  val filePath = call.argument<String>("filePath")
  installApk(filePath)
  result.success(null)
  }
  }
  }

  private fun installApk(filePath: String?) {
  if (filePath == null) return
  val file = File(filePath)
  val intent = Intent(Intent.ACTION_VIEW)
  intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
  val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
  FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
  } else {
  Uri.fromFile(file)
  }
  intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
  intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
  startActivity(intent)
  }
}
