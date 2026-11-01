package com.rinduramadan.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Folder cadangan pilihan pengguna lewat Storage Access Framework: izin
 * baca-tulis folder disimpan permanen (takePersistableUriPermission), jadi
 * cadangan otomatis bisa ditulis tanpa izin penyimpanan luas & tetap ada
 * sesudah aplikasi dihapus. Kanal `bilalplus/backup_folder`.
 */
class BackupFolder(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "pick" -> pick(result)
                "write" -> result.success(
                    write(
                        Uri.parse(call.argument<String>("tree")!!),
                        call.argument<String>("name")!!,
                        call.argument<ByteArray>("bytes")!!,
                    ),
                )
                "list" -> result.success(list(Uri.parse(call.argument<String>("tree")!!)))
                "read" -> result.success(read(Uri.parse(call.argument<String>("doc")!!)))
                "delete" -> result.success(delete(Uri.parse(call.argument<String>("doc")!!)))
                "hasAccess" -> result.success(hasAccess(Uri.parse(call.argument<String>("tree")!!)))
                "release" -> {
                    release(Uri.parse(call.argument<String>("tree")!!))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("backup_folder", e.message ?: e.javaClass.simpleName, null)
        }
    }

    private fun pick(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("backup_folder", "Pemilih folder sedang terbuka", null)
            return
        }
        pending = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
        )
        activity.startActivityForResult(intent, REQUEST_PICK)
    }

    /** Dipanggil dari MainActivity.onActivityResult; true bila hasil ini miliknya. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK) return false
        val r = pending
        pending = null
        val uri = data?.data
        if (r == null) return true
        if (resultCode != Activity.RESULT_OK || uri == null) {
            r.success(null) // dibatalkan
            return true
        }
        try {
            activity.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            r.success(mapOf("uri" to uri.toString(), "name" to folderLabel(uri)))
        } catch (e: Exception) {
            r.error("backup_folder", e.message ?: e.javaClass.simpleName, null)
        }
        return true
    }

    private fun treeDoc(tree: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))

    private fun write(tree: Uri, name: String, bytes: ByteArray): String {
        val doc = DocumentsContract.createDocument(
            activity.contentResolver, treeDoc(tree), "application/json", name,
        ) ?: throw IllegalStateException("Gagal membuat berkas di folder")
        activity.contentResolver.openOutputStream(doc, "w")?.use { it.write(bytes) }
            ?: throw IllegalStateException("Gagal menulis berkas")
        return doc.toString()
    }

    private fun list(tree: Uri): List<Map<String, Any?>> {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(
            tree, DocumentsContract.getTreeDocumentId(tree),
        )
        val out = ArrayList<Map<String, Any?>>()
        activity.contentResolver.query(
            children,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                DocumentsContract.Document.COLUMN_SIZE,
            ),
            null, null, null,
        )?.use { c ->
            while (c.moveToNext()) {
                val name = c.getString(1) ?: continue
                if (!isCopy(name)) continue
                out.add(
                    mapOf(
                        "uri" to DocumentsContract.buildDocumentUriUsingTree(tree, c.getString(0)).toString(),
                        "name" to name,
                        "modified" to c.getLong(2),
                        "size" to c.getLong(3),
                    ),
                )
            }
        }
        return out
    }

    private fun read(doc: Uri): ByteArray =
        activity.contentResolver.openInputStream(doc)?.use { it.readBytes() }
            ?: throw IllegalStateException("Gagal membaca berkas")

    private fun delete(doc: Uri): Boolean = DocumentsContract.deleteDocument(activity.contentResolver, doc)

    private fun hasAccess(tree: Uri): Boolean =
        activity.contentResolver.persistedUriPermissions.any {
            it.uri == tree && it.isReadPermission && it.isWritePermission
        }

    private fun release(tree: Uri) {
        try {
            activity.contentResolver.releasePersistableUriPermission(
                tree,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (_: Exception) {
        }
    }

    companion object {
        const val REQUEST_PICK = 4711

        /** Awalan & akhiran nama berkas cadangan otomatis. */
        const val PREFIX = "bilalplus-cadangan-"
        const val SUFFIX = ".json"

        fun isCopy(name: String): Boolean = name.startsWith(PREFIX) && name.endsWith(SUFFIX)

        /** "primary:Documents/Cadangan" -> "Documents/Cadangan". */
        fun folderLabel(tree: Uri): String {
            val id = try { DocumentsContract.getTreeDocumentId(tree) } catch (_: Exception) { return "Folder terpilih" }
            val path = id.substringAfter(':', "")
            return if (path.isEmpty()) "Penyimpanan internal" else path
        }
    }
}
