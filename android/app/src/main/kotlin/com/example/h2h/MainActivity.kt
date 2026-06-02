package com.example.h2h

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create notification channels for FCM push notifications
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "high_importance_channel",
                "High Importance Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "This channel is used for important partner notifications."
                enableLights(true)
                enableVibration(true)
            }
            
            val silentChannel = NotificationChannel(
                "silent_importance_channel",
                "Silent Notifications",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "This channel is used for silent partner notifications."
                enableLights(true)
                enableVibration(false)
                setSound(null, null)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
            manager?.createNotificationChannel(silentChannel)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Pass new intent to Flutter engine so home_widget interactivity callback fires
        setIntent(intent)
    }
}
