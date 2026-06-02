package com.example.h2h

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
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
        val statusMessage = prefs.getString("status_message", "No taps received yet") ?: "No taps received yet"
        val receivedNote = prefs.getString("received_note", "No notes yet") ?: "No notes yet"

        // Update all active widget instances on the home screen
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.love_widget)
            
            // Set dynamic partner name and interaction details
            views.setTextViewText(R.id.widget_title, partnerName)
            views.setTextViewText(R.id.widget_status, statusMessage)
            views.setTextViewText(R.id.widget_note_text, receivedNote)

            // 1. Core Heart tap — opens app (intentional: big heart opens full app)
            val heartIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("homewidget://send_love?type=love_tap")
            )
            views.setOnClickPendingIntent(R.id.widget_main_heart, heartIntent)

            // 2. Miss You emoji tap — sends in BACKGROUND without opening the app
            val missYouIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("homewidget://send_love?type=miss_you")
            )
            views.setOnClickPendingIntent(R.id.widget_emoji_miss_you, missYouIntent)

            // 3. Sad emoji tap — background send
            val sadIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("homewidget://send_love?type=sad")
            )
            views.setOnClickPendingIntent(R.id.widget_emoji_sad, sadIntent)

            // 4. Excited emoji tap — background send
            val excitedIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("homewidget://send_love?type=excited")
            )
            views.setOnClickPendingIntent(R.id.widget_emoji_excited, excitedIntent)

            // 5. Thinking emoji tap — background send
            val thinkingIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("homewidget://send_love?type=thinking")
            )
            views.setOnClickPendingIntent(R.id.widget_emoji_thinking, thinkingIntent)

            // Commit visual update
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
