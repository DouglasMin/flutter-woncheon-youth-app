package com.woncheon.woncheon_youth

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class WoncheonMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // 앱이 살아 있으면 MethodChannel 로 Dart에 전달. 죽어 있으면 다음 앱 실행 시
        // FirebaseMessaging.getInstance().token 으로 가져갈 수 있어 손실 없음.
        MainActivity.cachedToken = token
        MainActivity.flushTokenToChannel()
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        val notif = message.notification
        val data = message.data
        val title = notif?.title ?: "원천청년부"
        val body = notif?.body ?: ""
        val screen = data["screen"]

        ensureNotificationChannel()

        val tapIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (screen != null) putExtra(MainActivity.EXTRA_SCREEN, screen)
        }
        val pending = PendingIntent.getActivity(
            this,
            0,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pending)

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(System.currentTimeMillis().toInt(), builder.build())
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "기도 알림",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "새 중보기도 알림"
        }
        nm.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID = "prayer_default"
    }
}
