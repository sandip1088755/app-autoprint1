package app.autoprint.pay

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.text.InputType
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : Activity() {

    private lateinit var etUrl: EditText
    private lateinit var etKey: EditText
    private lateinit var tvStatus: TextView
    private lateinit var tvLog: TextView
    private val ui = Handler(Looper.getMainLooper())
    private val refresher = object : Runnable {
        override fun run() {
            refresh()
            ui.postDelayed(this, 3000)
        }
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    private fun btn(label: String, primary: Boolean, onClick: () -> Unit): Button {
        val b = Button(this)
        b.text = label
        b.setAllCaps(false)
        if (primary) {
            b.setBackgroundColor(Color.parseColor("#2563EB"))
            b.setTextColor(Color.WHITE)
        }
        val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        lp.topMargin = dp(8)
        b.layoutParams = lp
        b.setOnClickListener { onClick() }
        return b
    }

    private fun label(t: String): TextView {
        val v = TextView(this)
        v.text = t
        v.setTextColor(Color.parseColor("#475569"))
        v.textSize = 12f
        v.setPadding(0, dp(14), 0, dp(4))
        return v
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.setPadding(dp(18), dp(28), dp(18), dp(28))

        val title = TextView(this)
        title.text = "AutoPrint Pay"
        title.textSize = 24f
        title.setTypeface(null, Typeface.BOLD)
        title.setTextColor(Color.parseColor("#0F172A"))
        root.addView(title)

        val sub = TextView(this)
        sub.text = "Is phone ke payment notification / SMS se AutoPrint order apne aap verify hote hain. Sirf \"paisa aaya\" jaise message aage bheje jate hain."
        sub.textSize = 13f
        sub.setTextColor(Color.parseColor("#64748B"))
        sub.setPadding(0, dp(4), 0, dp(8))
        root.addView(sub)

        tvStatus = TextView(this)
        tvStatus.textSize = 14f
        tvStatus.setLineSpacing(0f, 1.25f)
        tvStatus.setTextColor(Color.parseColor("#0F172A"))
        tvStatus.setPadding(dp(12), dp(10), dp(12), dp(10))
        tvStatus.setBackgroundColor(Color.parseColor("#F1F5F9"))
        root.addView(tvStatus)

        root.addView(label("WEBHOOK URL (shop panel Settings se)"))
        etUrl = EditText(this)
        etUrl.inputType = InputType.TYPE_TEXT_VARIATION_URI
        etUrl.setSingleLine(false)
        etUrl.textSize = 12f
        etUrl.setText(Config.url(this))
        root.addView(etUrl)

        root.addView(label("SECRET KEY"))
        etKey = EditText(this)
        etKey.inputType = InputType.TYPE_CLASS_TEXT
        etKey.textSize = 13f
        etKey.setText(Config.key(this))
        root.addView(etKey)

        root.addView(btn("💾 Save", true) { saveFields() })
        root.addView(btn("🧪 Test bhejo", false) { sendTest() })

        root.addView(label("PERMISSIONS"))
        root.addView(btn("1. Notification access do", false) {
            startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
        })
        root.addView(btn("2. SMS permission do (optional)", false) {
            if (Build.VERSION.SDK_INT >= 23) requestPermissions(arrayOf(Manifest.permission.RECEIVE_SMS), 11)
        })
        root.addView(btn("3. Battery restriction hatao", false) { askBattery() })

        root.addView(label("AAKHRI EVENTS"))
        tvLog = TextView(this)
        tvLog.textSize = 12f
        tvLog.setLineSpacing(0f, 1.2f)
        tvLog.setTextColor(Color.parseColor("#334155"))
        root.addView(tvLog)

        val sv = ScrollView(this)
        sv.addView(root)
        setContentView(sv)

        handleDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDeepLink(intent)
    }

    override fun onResume() {
        super.onResume()
        // Notification listener band hua ho to dobara jodne ki koshish
        if (Build.VERSION.SDK_INT >= 24 && listenerEnabled()) {
            try {
                NotificationListenerService.requestRebind(ComponentName(this, PayListener::class.java))
            } catch (e: Exception) {
            }
        }
        ui.post(refresher)
    }

    override fun onPause() {
        super.onPause()
        ui.removeCallbacks(refresher)
    }

    private fun handleDeepLink(i: Intent?) {
        val data: Uri = i?.data ?: return
        if (data.scheme != "autoprintpay") return
        val u = data.getQueryParameter("u") ?: return
        val k = data.getQueryParameter("k") ?: return
        if (!u.startsWith("https://")) {
            Toast.makeText(this, "Sirf https URL allowed hai", Toast.LENGTH_LONG).show()
            return
        }
        AlertDialog.Builder(this)
            .setTitle("Setup karna hai?")
            .setMessage("Payment notifications is URL par bheje jayenge:\n\n$u\n\nSirf tab Allow karo jab ye tumhare AutoPrint shop ka URL ho.")
            .setPositiveButton("Allow") { _, _ ->
                Config.save(this, u, k)
                etUrl.setText(u)
                etKey.setText(k)
                Toast.makeText(this, "Setup save ho gaya", Toast.LENGTH_SHORT).show()
                refresh()
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun saveFields() {
        val u = etUrl.text.toString().trim()
        val k = etKey.text.toString().trim()
        if (!u.startsWith("https://")) {
            Toast.makeText(this, "URL https:// se shuru hona chahiye", Toast.LENGTH_LONG).show()
            return
        }
        if (k.isEmpty()) {
            Toast.makeText(this, "Secret key daalo", Toast.LENGTH_LONG).show()
            return
        }
        Config.save(this, u, k)
        Toast.makeText(this, "Save ho gaya", Toast.LENGTH_SHORT).show()
        refresh()
    }

    private fun sendTest() {
        saveFields()
        if (!Config.isReady(this)) return
        Sender.send(this, "AUTOPRINT-TEST " + System.currentTimeMillis(), "app-test")
        Toast.makeText(this, "Test bheja, neeche events me dekho", Toast.LENGTH_SHORT).show()
    }

    private fun askBattery() {
        try {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            if (Build.VERSION.SDK_INT >= 23 && !pm.isIgnoringBatteryOptimizations(packageName)) {
                startActivity(
                    Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        .setData(Uri.parse("package:$packageName"))
                )
            } else {
                Toast.makeText(this, "Battery restriction pehle se hati hui hai", Toast.LENGTH_SHORT).show()
            }
        } catch (e: Exception) {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }

    private fun listenerEnabled(): Boolean {
        val s = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
        return s.contains(packageName)
    }

    private fun smsGranted(): Boolean =
        Build.VERSION.SDK_INT < 23 || checkSelfPermission(Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED

    private fun batteryOk(): Boolean {
        if (Build.VERSION.SDK_INT < 23) return true
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    private fun refresh() {
        val ok = "✅"
        val no = "❌"
        tvStatus.text =
            (if (Config.isReady(this)) ok else no) + " Setup (URL + key)\n" +
            (if (listenerEnabled()) ok else no) + " Notification access\n" +
            (if (smsGranted()) ok else "➖") + " SMS permission (optional)\n" +
            (if (batteryOk()) ok else "⚠️") + " Battery restriction hata di"

        val fmt = SimpleDateFormat("dd MMM, hh:mm:ss a", Locale.getDefault())
        val lines = Config.logLines(this)
        tvLog.text = if (lines.isEmpty()) "Abhi koi event nahi." else
            lines.joinToString("\n\n") { fmt.format(Date(it.first)) + "\n" + it.second }
    }

    @Deprecated("Deprecated in Java")
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        refresh()
    }
}
