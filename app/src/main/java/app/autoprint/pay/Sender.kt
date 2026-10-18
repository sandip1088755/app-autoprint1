package app.autoprint.pay

import android.content.Context
import android.os.Handler
import android.os.Looper
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Message ko queue me rakhta hai aur webhook par POST karta hai. Fail ho to 30 second baad dobara. */
object Sender {
    private val exec = Executors.newSingleThreadExecutor()
    private val handler = Handler(Looper.getMainLooper())
    private val retryPending = AtomicBoolean(false)
    private const val MAX_AGE_MS = 20 * 60 * 1000L   // 20 min se purani payment ka matlab nahi
    private const val MAX_TRIES = 6

    fun send(ctx: Context, text: String, source: String) {
        val app = ctx.applicationContext
        exec.execute {
            enqueue(app, text, source)
            flush(app)
        }
    }

    // ---------- queue ----------
    private fun prefs(c: Context) = c.getSharedPreferences("queue", Context.MODE_PRIVATE)

    @Synchronized
    private fun load(c: Context): JSONArray =
        try { JSONArray(prefs(c).getString("q", "[]")) } catch (e: Exception) { JSONArray() }

    @Synchronized
    private fun store(c: Context, arr: JSONArray) {
        prefs(c).edit().putString("q", arr.toString()).apply()
    }

    @Synchronized
    private fun enqueue(c: Context, text: String, source: String) {
        val arr = load(c)
        arr.put(
            JSONObject().put("id", System.nanoTime()).put("t", System.currentTimeMillis())
                .put("text", text).put("src", source).put("tries", 0)
        )
        store(c, arr)
    }

    // ---------- send ----------
    private fun flush(app: Context) {
        var needRetry = false
        val arr = synchronized(this) { load(app) }
        val keep = JSONArray()
        for (i in 0 until arr.length()) {
            val o = arr.getJSONObject(i)
            val age = System.currentTimeMillis() - o.getLong("t")
            if (age > MAX_AGE_MS) {
                Config.log(app, "⏱️ Purana message chhod diya")
                continue
            }
            val r = post(app, o.getString("text"), o.getString("src"))
            if (r.done) {
                Config.log(app, r.label + " · " + preview(o.getString("text")))
            } else {
                val tries = o.getInt("tries") + 1
                if (tries >= MAX_TRIES) {
                    Config.log(app, "❌ " + r.label + " (chhod diya) · " + preview(o.getString("text")))
                } else {
                    Config.log(app, "🔁 " + r.label + " (dobara try karenge)")
                    o.put("tries", tries)
                    keep.put(o)
                    needRetry = true
                }
            }
        }
        synchronized(this) { store(app, keep) }
        if (needRetry && retryPending.compareAndSet(false, true)) {
            handler.postDelayed({
                retryPending.set(false)
                exec.execute { flush(app) }
            }, 30_000L)
        }
    }

    private class Result(val done: Boolean, val label: String)

    private fun preview(t: String) = if (t.length > 60) t.substring(0, 60) + "…" else t

    private fun post(app: Context, text: String, source: String): Result {
        return try {
            val body = "key=" + URLEncoder.encode(Config.key(app), "UTF-8") +
                "&message=" + URLEncoder.encode(text, "UTF-8") +
                "&source=" + URLEncoder.encode(source, "UTF-8")
            val conn = URL(Config.url(app)).openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.connectTimeout = 15_000
            conn.readTimeout = 20_000
            conn.doOutput = true
            conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
            conn.setRequestProperty("User-Agent", "AutoPrintPay/1.0")
            conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
            val code = conn.responseCode
            val stream = if (code >= 400) conn.errorStream else conn.inputStream
            val resp = stream?.let { s -> BufferedReader(InputStreamReader(s)).use { it.readText() } } ?: ""
            conn.disconnect()

            when {
                code == 403 -> Result(true, "❌ Galat key ya shop band hai")
                code in 400..499 -> Result(true, "❌ Server ne mana kiya ($code)")
                code >= 500 -> Result(false, "Server error ($code)")
                resp.contains("\"ok\":true") -> {
                    val m = Regex("\"result\":\"([a-z_]+)\"").find(resp)?.groupValues?.get(1) ?: "ok"
                    Result(true, friendly(m))
                }
                else -> Result(false, "Server ka jawab galat (URL me ?i=1 hai?)")
            }
        } catch (e: Exception) {
            Result(false, "Internet/Server dikkat")
        }
    }

    private fun friendly(r: String) = when (r) {
        "matched" -> "✅ Payment match hui"
        "test_ok" -> "🧪 Test pass"
        "unmatched" -> "⚠️ Koi pending order match nahi hua"
        "ambiguous" -> "🔀 Ek amount ke kai orders, customer UTR se verify karega"
        "duplicate" -> "➖ Duplicate"
        "ignored" -> "➖ Credit nahi tha"
        else -> "✅ $r"
    }
}
