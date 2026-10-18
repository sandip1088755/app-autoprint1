package app.autoprint.pay

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/** PhonePe / GPay / Paytm / bank apps ke "paisa aaya" notification padhta hai. */
class PayListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        if (sbn.packageName == packageName) return
        val n = sbn.notification ?: return
        if ((n.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return
        if (!Config.isReady(this)) return

        val ex = n.extras ?: return
        val title = ex.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = ex.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val big = ex.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val bodyText = if (big.isNotBlank()) big else text
        val body = listOf(title, bodyText).filter { it.isNotBlank() }.joinToString(" - ")
        if (body.isBlank()) return

        if (!PayFilter.looksLikeCredit(body)) return
        if (PayFilter.isDuplicate(body)) return

        Sender.send(this, body, "notif:" + sbn.packageName)
    }
}
