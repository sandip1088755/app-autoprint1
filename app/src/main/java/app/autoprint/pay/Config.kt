package app.autoprint.pay

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Webhook URL + secret key, aur chhota event log. */
object Config {
    private fun prefs(c: Context) = c.getSharedPreferences("cfg", Context.MODE_PRIVATE)

    fun url(c: Context): String = prefs(c).getString("url", "") ?: ""
    fun key(c: Context): String = prefs(c).getString("key", "") ?: ""

    fun save(c: Context, url: String, key: String) {
        prefs(c).edit().putString("url", url.trim()).putString("key", key.trim()).apply()
    }

    fun isReady(c: Context): Boolean = url(c).startsWith("https://") && key(c).isNotBlank()

    // ---- event log (aakhri 30) ----
    @Synchronized
    fun log(c: Context, msg: String) {
        val p = prefs(c)
        val arr = try { JSONArray(p.getString("log", "[]")) } catch (e: Exception) { JSONArray() }
        val o = JSONObject().put("t", System.currentTimeMillis()).put("m", msg)
        val out = JSONArray()
        out.put(o)
        var i = 0
        while (i < arr.length() && out.length() < 30) {
            out.put(arr.get(i))
            i++
        }
        p.edit().putString("log", out.toString()).apply()
    }

    @Synchronized
    fun logLines(c: Context): List<Pair<Long, String>> {
        val arr = try { JSONArray(prefs(c).getString("log", "[]")) } catch (e: Exception) { JSONArray() }
        val res = ArrayList<Pair<Long, String>>()
        for (i in 0 until arr.length()) {
            val o = arr.getJSONObject(i)
            res.add(Pair(o.getLong("t"), o.getString("m")))
        }
        return res
    }
}
