package com.woncheon.woncheon_youth

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.google.android.gms.tasks.OnCompleteListener
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> handleRequestPermission(result)
                    "testNotification" -> {
                        // Android 쪽 로컬 테스트는 사용 안 함 — 백엔드 sendTest 함수로 검증.
                        result.success(false)
                    }
                    "clearBadge" -> {
                        // Android 시스템에 표준 badge API 없음 — no-op.
                        result.success(null)
                    }
                    "getDeviceToken" -> handleGetDeviceToken(result)
                    else -> result.notImplemented()
                }
            }
        }
        instance = this
        // 캐시된 토큰이 있으면 즉시 전달
        flushTokenToChannel()
        // 항상 최신 토큰을 한 번 가져와서 등록
        fetchAndPushToken()

        // 알림 탭으로 시작했을 경우 deep link
        intent?.getStringExtra(EXTRA_SCREEN)?.let { screen ->
            channel?.invokeMethod("onNotificationTapped", screen)
            intent.removeExtra(EXTRA_SCREEN)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.getStringExtra(EXTRA_SCREEN)?.let { screen ->
            channel?.invokeMethod("onNotificationTapped", screen)
            intent.removeExtra(EXTRA_SCREEN)
        }
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        channel = null
        super.onDestroy()
    }

    private fun handleRequestPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            // Android 12 이하: 권한 자동 부여
            result.success(true)
            return
        }
        val granted = checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED
        if (granted) {
            result.success(true)
            return
        }
        permissionResultHandler = result
        requestPermissions(
            arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
            REQ_NOTIF_PERMISSION,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_NOTIF_PERMISSION) {
            val granted = grantResults.firstOrNull() ==
                android.content.pm.PackageManager.PERMISSION_GRANTED
            permissionResultHandler?.success(granted)
            permissionResultHandler = null
        }
    }

    private fun fetchAndPushToken() {
        FirebaseMessaging.getInstance().token.addOnCompleteListener(
            OnCompleteListener { task ->
                if (!task.isSuccessful) {
                    android.util.Log.e(
                        "WoncheonPush",
                        "FCM getToken 실패",
                        task.exception,
                    )
                    return@OnCompleteListener
                }
                val token = task.result ?: return@OnCompleteListener
                cachedToken = token
                flushTokenToChannel()
            },
        )
    }

    /// Dart에서 직접 호출. 캐시된 토큰이 있으면 즉시 반환, 없으면
    /// Firebase에서 비동기로 가져와서 반환. listener race를 우회.
    /// addOnCompleteListener 콜백은 워커 스레드에서 실행되므로 result 응답은
    /// 반드시 메인 스레드로 dispatch 해야 한다.
    private fun handleGetDeviceToken(result: MethodChannel.Result) {
        val cached = cachedToken
        if (cached != null) {
            result.success(cached)
            return
        }
        val mainHandler = Handler(Looper.getMainLooper())
        FirebaseMessaging.getInstance().token.addOnCompleteListener(
            OnCompleteListener { task ->
                if (!task.isSuccessful) {
                    android.util.Log.e(
                        "WoncheonPush",
                        "getDeviceToken FCM 실패",
                        task.exception,
                    )
                    mainHandler.post { result.success(null) }
                    return@OnCompleteListener
                }
                val token = task.result
                cachedToken = token
                mainHandler.post { result.success(token) }
            },
        )
    }

    private var permissionResultHandler: MethodChannel.Result? = null

    companion object {
        const val CHANNEL_NAME = "com.woncheon.youth/push"
        const val EXTRA_SCREEN = "extra_screen"
        private const val REQ_NOTIF_PERMISSION = 9001

        @Volatile
        var instance: MainActivity? = null

        @Volatile
        var cachedToken: String? = null

        /// FirebaseMessagingService.onNewToken() 은 백그라운드 스레드에서 호출되므로
        /// MethodChannel 호출은 반드시 메인 스레드로 dispatch 해야 한다.
        fun flushTokenToChannel() {
            val token = cachedToken ?: return
            Handler(Looper.getMainLooper()).post {
                instance?.channel?.invokeMethod("onTokenReceived", token)
            }
        }
    }
}
