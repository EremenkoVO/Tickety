package com.tickety.tickety

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Context.MODE_PRIVATE
import android.content.Intent
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews

class TicketyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", MODE_PRIVATE)
            val hasEvent = prefs.getString("widget_has_event", "false") == "true"

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            if (!hasEvent) {
                views.setViewVisibility(R.id.widget_content, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_content, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)

                val imagePath = prefs.getString("widget_image_path", null)
                if (!imagePath.isNullOrEmpty()) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.widget_strip_image, bitmap)
                        views.setViewVisibility(R.id.widget_strip_image, View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_strip_image, View.GONE)
                    }
                } else {
                    views.setViewVisibility(R.id.widget_strip_image, View.GONE)
                }

                val eventName = prefs.getString("widget_event_name", "") ?: ""
                val date = prefs.getString("widget_date_formatted", "") ?: ""
                val venue = prefs.getString("widget_venue", "") ?: ""

                views.setTextViewText(R.id.widget_event_name, eventName)
                views.setTextViewText(R.id.widget_date, date)
                views.setTextViewText(R.id.widget_venue, venue)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
