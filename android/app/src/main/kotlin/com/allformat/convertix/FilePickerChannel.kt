package com.allformat.convertix

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.MediaStore

class FilePickerChannel(private val activity: Activity) {

    private val prefs = activity.getSharedPreferences(
        "convertix_source_prefs", Context.MODE_PRIVATE
    )

    // Called from Dart to launch a file picker for a specific tool
    fun launchPicker(
        toolName: String,
        mimeType: String,
        allowMultiple: Boolean,
        requestCode: Int
    ) {
        val remembered = prefs.getString("source_$toolName", null)
        
        if (remembered != null) {
            // Try to launch remembered app directly
            val cn = ComponentName.unflattenFromString(remembered)
            if (cn != null && isAppInstalled(cn.packageName)) {
                val intent = buildPickIntent(mimeType, allowMultiple).apply {
                    setPackage(cn.packageName)
                }
                try {
                    activity.startActivityForResult(intent, requestCode)
                    return
                } catch (e: Exception) {
                    // If direct launch failed, clear preference and fall through to chooser
                    prefs.edit().remove("source_$toolName").apply()
                }
            } else {
                // App uninstalled — clear preference, fall through to chooser
                prefs.edit().remove("source_$toolName").apply()
            }
        }

        // No preference or uninstalled — show native Android Intent Resolver / Chooser
        val base = buildPickIntent(mimeType, allowMultiple)
        
        val receiver = Intent(activity, ChooserReceiver::class.java).apply {
            putExtra("toolName", toolName)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
        } else {
            android.app.PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pi = android.app.PendingIntent.getBroadcast(
            activity,
            requestCode,
            receiver,
            flags
        )
        val chooser = Intent.createChooser(base, "Select file", pi.intentSender)

        // Augment media tools with ACTION_PICK for OEM Gallery apps if not in GET_CONTENT
        val extraIntents = mutableListOf<Intent>()
        if (mimeType.startsWith("image/")) {
            val pickIntent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
                type = mimeType
                if (allowMultiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
            val getContentPackages = activity.packageManager.queryIntentActivities(base, 0)
                .map { it.activityInfo.packageName }
                .toSet()
            val pickActivities = activity.packageManager.queryIntentActivities(pickIntent, 0)
            for (res in pickActivities) {
                val pkg = res.activityInfo.packageName
                if (!getContentPackages.contains(pkg)) {
                    val target = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
                        type = mimeType
                        setPackage(pkg)
                        if (allowMultiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    }
                    extraIntents.add(target)
                }
            }
        } else if (mimeType.startsWith("video/")) {
            val pickIntent = Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI).apply {
                type = mimeType
                if (allowMultiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
            val getContentPackages = activity.packageManager.queryIntentActivities(base, 0)
                .map { it.activityInfo.packageName }
                .toSet()
            val pickActivities = activity.packageManager.queryIntentActivities(pickIntent, 0)
            for (res in pickActivities) {
                val pkg = res.activityInfo.packageName
                if (!getContentPackages.contains(pkg)) {
                    val target = Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI).apply {
                        type = mimeType
                        setPackage(pkg)
                        if (allowMultiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    }
                    extraIntents.add(target)
                }
            }
        }

        if (extraIntents.isNotEmpty()) {
            chooser.putExtra(Intent.EXTRA_INITIAL_INTENTS, extraIntents.toTypedArray())
        }

        activity.startActivityForResult(chooser, requestCode)
    }

    // Called when a result is received — store the chosen component if resolved
    fun onPickResult(toolName: String, resultData: Intent?) {
        val component = resultData?.resolveActivity(activity.packageManager)
        if (component != null && component.packageName != "android") {
            prefs.edit()
                .putString("source_$toolName", component.flattenToString())
                .apply()
        }
    }

    // Called from Dart to get current preferences (for Settings display)
    fun getPreferences(): Map<String, String> {
        return prefs.all
            .filter { it.key.startsWith("source_") }
            .mapKeys { it.key.removePrefix("source_") }
            .mapValues { entry ->
                val cn = ComponentName.unflattenFromString(entry.value as String)
                cn?.let { getAppLabel(it.packageName) } ?: "Unknown"
            }
    }

    // Called from Dart to reset one tool's preference
    fun resetPreference(toolName: String) {
        prefs.edit().remove("source_$toolName").apply()
    }

    // Called from Dart to reset all preferences
    fun resetAllPreferences() {
        val keys = prefs.all.keys.filter { it.startsWith("source_") }
        prefs.edit().apply { keys.forEach { remove(it) } }.apply()
    }

    private fun buildPickIntent(mimeType: String, allowMultiple: Boolean): Intent {
        return Intent(Intent.ACTION_GET_CONTENT).apply {
            if (mimeType.contains(",")) {
                type = "*/*"
                putExtra(Intent.EXTRA_MIME_TYPES, mimeType.split(",").toTypedArray())
            } else {
                type = mimeType
            }
            if (allowMultiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            activity.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) { false }
    }

    private fun getAppLabel(packageName: String): String {
        return try {
            val info = activity.packageManager.getApplicationInfo(packageName, 0)
            activity.packageManager.getApplicationLabel(info).toString()
        } catch (e: Exception) { packageName }
    }
}
