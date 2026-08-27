package com.allformat.convertix

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private lateinit var filePickerChannel: FilePickerChannel
    private var pendingResult: MethodChannel.Result? = null
    private var pendingToolName: String? = null

    private val PICK_FILE_REQUEST_CODE = 9001

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == PICK_FILE_REQUEST_CODE) {
            val methodResult = pendingResult
            val toolName = pendingToolName
            pendingResult = null
            pendingToolName = null

            if (methodResult == null) return

            if (resultCode != Activity.RESULT_OK || data == null) {
                methodResult.success(emptyList<String>())
                return
            }


            if (toolName != null) {
                filePickerChannel.onPickResult(toolName, data)
            }

            val uris = extractUris(data)
            if (uris.isEmpty()) {
                methodResult.success(emptyList<String>())
                return
            }

            val paths = mutableListOf<String>()
            for (uri in uris) {
                val copied = runCatching { copyToCache(uri) }.getOrNull()
                if (copied != null) paths += copied
            }

            if (paths.isEmpty()) {
                methodResult.error(
                    "copy_failed",
                    "The selected file could not be read. It may have been moved or is on a provider that denies access.",
                    null,
                )
            } else {
                methodResult.success(paths)
            }
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Phase 5A — output placement.
        MethodChannel(messenger, MEDIA_STORE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToCollection" -> handleSaveToCollection(call, result)
                "showInFolder" -> handleShowInFolder(call, result)
                "deleteOutputs" -> handleDeleteOutputs(call, result)
                else -> result.notImplemented()
            }
        }

        // Phase 6B — File Picker Channel
        filePickerChannel = FilePickerChannel(this)

        MethodChannel(messenger, FILE_PICKER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchPicker" -> {
                    if (pendingResult != null) {
                        result.error("pick_in_progress", "Another pick is already in progress", null)
                        return@setMethodCallHandler
                    }
                    val toolName = call.argument<String>("toolName")
                    val mimeType = call.argument<String>("mimeType")
                    val allowMultiple = call.argument<Boolean>("allowMultiple") ?: false

                    if (toolName == null || mimeType == null) {
                        result.error("bad_arguments", "launchPicker requires toolName and mimeType", null)
                        return@setMethodCallHandler
                    }

                    pendingResult = result
                    pendingToolName = toolName
                    try {
                        filePickerChannel.launchPicker(toolName, mimeType, allowMultiple, PICK_FILE_REQUEST_CODE)
                    } catch (e: android.content.ActivityNotFoundException) {
                        pendingResult = null
                        pendingToolName = null
                        result.error(
                            "source_unavailable",
                            "No app found that can open this file type. Please install a file manager like Files by Google.",
                            null,
                        )
                    }
                }
                "getPreferences" -> result.success(filePickerChannel.getPreferences())
                "resetPreference" -> {
                    val toolName = call.argument<String>("toolName")
                    if (toolName != null) filePickerChannel.resetPreference(toolName)
                    result.success(true)
                }
                "resetAllPreferences" -> {
                    filePickerChannel.resetAllPreferences()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // --- Phase 5A ---------------------------------------------------------------------------

    private fun handleSaveToCollection(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val collection = call.argument<String>("collection")
        val relativeDir = call.argument<String>("relativeDir")
        val displayName = call.argument<String>("displayName")

        if (sourcePath == null || collection == null || relativeDir == null || displayName == null) {
            result.error(
                "bad_arguments",
                "saveToCollection requires sourcePath, collection, relativeDir and displayName",
                null,
            )
            return
        }

        when (
            val outcome = MediaStoreWriter(applicationContext)
                .save(sourcePath, collection, relativeDir, displayName)
        ) {
            is MediaStoreWriter.Result.Success -> result.success(
                mapOf(
                    "uri" to outcome.uri,
                    "displayName" to outcome.displayName,
                    "relativeDir" to outcome.relativeDir,
                ),
            )

            is MediaStoreWriter.Result.Failure -> result.error(
                outcome.code,
                outcome.message,
                null,
            )
        }
    }

    private fun handleShowInFolder(call: MethodCall, result: MethodChannel.Result) {
        val relativeDir = call.argument<String>("relativeDir")
        if (relativeDir == null) {
            result.error("bad_arguments", "showInFolder requires relativeDir", null)
            return
        }

        try {
            val uri = android.provider.DocumentsContract.buildDocumentUri(
                "com.android.externalstorage.documents", 
                "primary:$relativeDir"
            )
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(uri, "vnd.android.document/directory")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("launch_failed", e.message, null)
        }
    }

    private fun handleDeleteOutputs(call: MethodCall, result: MethodChannel.Result) {
        val uris = call.argument<List<String>>("uris")
        if (uris == null) {
            result.error("bad_arguments", "deleteOutputs requires uris", null)
            return
        }
        result.success(MediaStoreWriter(applicationContext).delete(uris))
    }

    // --- Phase 6B Utilities -----------------------------------------------------------------

    private fun extractUris(data: Intent): List<Uri> {
        data.clipData?.let { clip ->
            return (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri }
        }
        return listOfNotNull(data.data)
    }

    private fun copyToCache(uri: Uri): String {
        val dir = File(cacheDir, PICK_DIR).apply { if (!exists()) mkdirs() }
        val name = displayNameFor(uri) ?: "input_${System.nanoTime()}"

        var target = File(dir, name)
        var counter = 1
        while (target.exists()) {
            val stem = name.substringBeforeLast('.', name)
            val ext = name.substringAfterLast('.', "")
            val suffix = if (ext.isEmpty()) "" else ".$ext"
            target = File(dir, "$stem-$counter$suffix")
            counter++
        }

        contentResolver.openInputStream(uri)?.use { input ->
            target.outputStream().use { out -> input.copyTo(out) }
        } ?: throw IllegalStateException("Could not open $uri")

        return target.absolutePath
    }

    private fun displayNameFor(uri: Uri): String? {
        val cursor: Cursor? = runCatching {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )
        }.getOrNull()

        cursor?.use {
            if (it.moveToFirst()) {
                val index = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0 && !it.isNull(index)) {
                    return it.getString(index)?.takeIf { name -> name.isNotBlank() }
                }
            }
        }
        return uri.lastPathSegment?.substringAfterLast('/')?.takeIf { it.contains('.') }
    }

    private companion object {
        const val MEDIA_STORE_CHANNEL = "com.allformat.convertix/media_store"
        const val FILE_PICKER_CHANNEL = "com.allformat.convertix/file_picker"
        const val PICK_DIR = "convertix_picks"
    }
}
