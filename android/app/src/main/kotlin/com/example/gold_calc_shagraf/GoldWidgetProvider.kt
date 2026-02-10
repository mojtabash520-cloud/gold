package com.example.gold_calc_shagraf

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class GoldWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                
                // دریافت قیمت از فلاتر
                val price = widgetData.getString("tv_price", "---")
                setTextViewText(R.id.tv_price, price)
                
                // دریافت زمان بروزرسانی از فلاتر
                val date = widgetData.getString("tv_date", "بروزرسانی: ...")
                setTextViewText(R.id.tv_date, date)
                
                // کلیک روی ویجت برای باز کردن برنامه
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
