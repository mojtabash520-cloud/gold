package com.example.gold_calc_shagraf

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class GoldWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // دریافت قیمت ذخیره شده توسط فلاتر
                val price = widgetData.getString("price_data", "درحال دریافت...")
                setTextViewText(R.id.widget_price, price)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
