package com.example.h2h

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create high-importance notification channel for FCM push notifications
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
            
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }

        // Handle widget tap URI intent (passes to home_widget interactivity callback in Flutter)
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle widget tap if app is already running
        handleWidgetIntent(intent)
    }

    private fun handleWidgetIntent(intent: Intent?) {
        if (intent?.data?.scheme == "homewidget") {
            HomeWidgetPlugin.handleIntent(context, intent)
        }
    }
}
