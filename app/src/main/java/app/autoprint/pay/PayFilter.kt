package app.autoprint.pay

/**
 * Sirf "paisa aaya" jaise notification/SMS aage bhejte hain.
 * Baaki notifications (WhatsApp, etc.) phone se bahar nahi jate.
 */
object PayFilter {
    private val amount = Regex("""(?:rs\.?|inr|₹)\s*[0-9][0-9,]*(?:\.[0-9]{1,2})?""", RegexOption.IGNORE_CASE)
    private val credit = Regex("""\b(credited|received|deposited|credit|added|cr)\b|\b(paid|sent) you\b""", RegexOption.IGNORE_CASE)
    private val debit = Regex("""\b(debited|withdrawn|paid to|sent to|you paid|you sent|spent|purchase|bill paid)\b""", RegexOption.IGNORE_CASE)

    fun looksLikeCredit(text: String): Boolean =
        amount.containsMatchIn(text) && credit.containsMatchIn(text) && !debit.containsMatchIn(text)

    private val seen = HashMap<Int, Long>()

    /** Same text 90 second ke andar dobara aaye to true (Android notification update karta rehta hai). */
    @Synchronized
    fun isDuplicate(text: String): Boolean {
        val now = System.currentTimeMillis()
        val iter = seen.entries.iterator()
        while (iter.hasNext()) {
            if (now - iter.next().value > 90_000L) iter.remove()
        }
        val h = text.hashCode()
        if (seen.containsKey(h)) return true
        seen[h] = now
        return false
    }
}
