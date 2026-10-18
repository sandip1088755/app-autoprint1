package app.autoprint.pay

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/** Bank SMS (optional): SMS permission dene par chalta hai. */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        if (!Config.isReady(context)) return
        val msgs = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        val body = msgs.joinToString("") { it.messageBody ?: "" }
        if (body.isBlank()) return
        if (!PayFilter.looksLikeCredit(body)) return
        if (PayFilter.isDuplicate(body)) return
        Sender.send(context, body, "sms")
    }
}
