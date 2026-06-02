package com.example.h2h

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import android.net.Uri

class LoveHeartWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Read data stored by the home_widget package in Flutter SharedPreferences
        val prefs: SharedPreferences = context.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE
        )
        val partnerName = prefs.getString("partner_name", "Partner") ?: "Partner"

        // Update all active widget instances on the home screen
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.love_heart_widget)
            
            // Set dynamic partner name
            views.setTextViewText(R.id.widget_title, partnerName)

            // Tappable Heart — sends a love tap directly in background (no app launch)
            val heartIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("homewidget://send_love?type=love_tap")
            )
            views.setOnClickPendingIntent(R.id.widget_main_heart, heartIntent)

            // Commit visual update
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
