package com.clipval

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Host activity + Android share intake.
 *
 * Share sheet SEND text/plain → stash payload → Flutter [com.clipval/share]
 * `takePendingShare` drains once (same contract as iOS App Group share).
 */
class MainActivity : FlutterFragmentActivity() {
  private val shareChannelName = "com.clipval/share"

  @Volatile private var pendingValue: String? = null
  @Volatile private var pendingTitle: String? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "takePendingShare" -> {
            val value = pendingValue?.trim().orEmpty()
            if (value.isEmpty()) {
              pendingValue = null
              pendingTitle = null
              result.success(null)
              return@setMethodCallHandler
            }
            val title = pendingTitle?.trim()
            pendingValue = null
            pendingTitle = null
            val map = hashMapOf<String, Any>("value" to value)
            if (!title.isNullOrEmpty()) {
              map["title"] = title
            }
            result.success(map)
          }
          else -> result.notImplemented()
        }
      }
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    captureShareIntent(intent)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    captureShareIntent(intent)
  }

  private fun captureShareIntent(intent: Intent?) {
    if (intent == null) return
    val action = intent.action ?: return
    if (action != Intent.ACTION_SEND) return
    val type = intent.type ?: return
    if (!type.startsWith("text/")) return

    val text =
      intent.getStringExtra(Intent.EXTRA_TEXT)?.trim().orEmpty().ifEmpty {
        // Some apps put body only in EXTRA_SUBJECT / ClipData
        intent.clipData?.getItemAt(0)?.coerceToText(this)?.toString()?.trim().orEmpty()
      }
    if (text.isEmpty()) return

    val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)?.trim()
    pendingValue = text
    pendingTitle =
      if (!subject.isNullOrEmpty() && subject != text) {
        subject.take(80)
      } else {
        null
      }

    // Avoid re-delivering the same share on rotate if activity recreated with same intent.
    intent.replaceExtras(Bundle())
    intent.action = Intent.ACTION_MAIN
  }
}
