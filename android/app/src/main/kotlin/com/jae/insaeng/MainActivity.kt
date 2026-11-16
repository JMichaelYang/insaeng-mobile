package com.jae.insaeng

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        intent.dropGlanceActionData()
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        intent.dropGlanceActionData()
        super.onNewIntent(intent)
    }
}

private fun Intent.dropGlanceActionData() {
    if (data?.scheme == "glance-action") {
        data = null
    }
}
