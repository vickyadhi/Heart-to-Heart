package com.example.h2h

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import android.net.Uri

class LoveWidgetProvider : AppWidgetProvider() {
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
        val statusMessage = prefs.getString("status_message", "No taps received yet 🥺") ?: "No taps received yet 🥺"

        // Update all active widget instances on the home screen
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.love_widget)
            
            // Set dynamic partner name and interaction details
            views.setTextViewText(R.id.widget_title, partnerName)
            views.setTextViewText(R.id.widget_status, statusMessage)

            // 1. Core Heart tap — uses HomeWidgetLaunchIntent (new interactivity API)
            val heartIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("homewidget://send_love?type=love_tap")
            )
            views.setOnClickPendingIntent(R.id.widget_main_heart, heartIntent)

            // 2. Miss You emoji tap
            val missYouIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("homewidget://send_love?type=miss_you")
            )
            views.setOnClickPendingIntent(R.id.widget_emoji_miss_you, missYouIntent)

            // 3. Sad emoji tap
            val sadIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("homewidget://send_love?type=sad")
            )
            views.setOnClickPendingIntent(R.id.widget_emoji_sad, sadIntent)

            // 4. Excited emoji tap
            val excitedIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("homewidget://send_love?type=excited")
            )
            views.setOnClickPendingIntent(R.id.widget_emoji_excited, excitedIntent)

            // 5. Thinking emoji tap
            val thinkingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("homewidget://send_love?type=thinking")
            )
            views.setOnClickPendingIntent(R.id.widget_emoji_thinking, thinkingIntent)

            // Commit visual update trigger
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
